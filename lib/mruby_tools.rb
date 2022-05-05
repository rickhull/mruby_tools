require 'open3'
require 'tempfile'

class MRubyTools
  class MRubyNotFound < RuntimeError; end

  MRUBY_DIR = File.expand_path("../mruby", __dir__)

  def self.mruby_dir
    ENV['MRUBY_DIR'] || MRUBY_DIR
  end

  attr_accessor :mruby_dir, :inc_path, :ar_path, :bin_path

  def initialize(mruby_dir = nil)
    @mruby_dir = mruby_dir || self.class.mruby_dir
    @inc_path = File.join(@mruby_dir, 'include')
    @ar_path = File.join(@mruby_dir, 'build', 'host', 'lib', 'libmruby.a')
    @bin_path = File.join(@mruby_dir, 'bin')
  end

  def src?
    File.directory?(@inc_path)
  end

  def built?
    File.readable?(@ar_path)
  end

  def validate!
    raise(MRubyNotFound, @inc_path) unless File.directory? @inc_path
    raise(MRubyNotFound, @ar_path) unless File.readable? @ar_path
    raise(MRubyNotFound, @bin_path) unless File.directory? @bin_path
    self
  end

  def gcc_args(c_file, out_file)
    ['-std=c99', "-I", @inc_path, c_file, "-o", out_file, @ar_path, '-lm']
  end

  def compile(c_file, out_file)
    Open3.capture3('gcc', *self.gcc_args(c_file, out_file))
  end

  # interpret several rb_files into a binary out_file contaning bytecode
  def mrbc(rb_files, out_file)
    Open3.capture3(File.join(@bin_path, 'mrbc'), '-o', out_file, *rb_files)
  end

  module C
    def self.slurp_mrb(bc_file, indent: '  ')
      test_symbol = File.read(bc_file).each_byte.reduce('') { |memo, b|
        memo + format("0x%0.2x,", b.ord)
      }
      ["/* #{bc_file} */",
       "test_symbol[] = {",
       test_symbol,
       "};",
      ].map { |s| indent + s }.join("\n")
    end

    def self.slurp_rb(rb_filename, indent: '  ')
      c_str = File.read(rb_filename)
      size = c_str.size
      c_str = c_str.gsub("\n", '\n').gsub('"', '\"')
      [ "/* #{rb_filename} */",
        'mrb_load_nstring(mrb, "' + c_str + '", ' + "#{size});",
        "check_exc(mrb, \"#{rb_filename}\");",
      ].map { |s| indent + s }.join("\n")
    end

    def self.bytecode_wrapper(bc_file)
      c_code = <<'EOF'
#include <stdlib.h>
#include <stdint.h>
#include <mruby.h>
#include <mruby/string.h>
#include <mruby/irep.h>

const uint8_t
#if defined __GNUC__
__attribute__((aligned(4)))
#elif defined _MSC_VER
__declspec(align(4))
#endif
EOF
      c_code += slurp_mrb(bc_file, indent: '') + "\n\n"

      c_code += <<'EOF'
void check_exc(mrb_state *mrb) {
  if (mrb->exc) {
    mrb_value exc = mrb_obj_value(mrb->exc);
    mrb_value exc_msg = mrb_funcall(mrb, exc, "to_s", 0);
    fprintf(stderr, "ERROR %s: %s\n",
            mrb_obj_classname(mrb, exc),
            mrb_str_to_cstr(mrb, exc_msg));
    /* mrb_print_backtrace(mrb);   # empty */
    exit(1);
  }
}

int
main(void)
{
  mrb_state *mrb = mrb_open();
  if (!mrb) {
    printf("mrb problem");
    exit(1);
  }
  mrb_load_irep(mrb, test_symbol);
  check_exc(mrb);
  mrb_close(mrb);
  return 0;
}
EOF
      c_code
    end

    def self.wrapper(rb_files)
      c_code = <<'EOF'
#include <stdlib.h>
#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/string.h>

void check_exc(mrb_state *mrb, char *filename) {
  if (mrb->exc) {
    mrb_value exc = mrb_obj_value(mrb->exc);
    mrb_value exc_msg = mrb_funcall(mrb, exc, "to_s", 0);
    fprintf(stderr, "ERROR in %s - %s: %s\n",
            filename,
            mrb_obj_classname(mrb, exc),
            mrb_str_to_cstr(mrb, exc_msg));
    /* mrb_print_backtrace(mrb);   # empty */
    exit(1);
  }
}

int
main(void)
{
  mrb_state *mrb = mrb_open();
  if (!mrb) {
    printf("mrb problem");
    exit(1);
  }
EOF
      c_code += rb_files.map { |rbf|
        "\n" + self.slurp_rb(rbf) + "\n\n"
      }.join

      c_code += <<EOF
  mrb_close(mrb);
  return 0;
}
EOF
      c_code
    end
  end

  module CLI
    USAGE_EXIT = 1

    def self.usage(msg = nil)
      puts <<EOF
  USAGE: mrbt file1.rb file2.rb ...
OPTIONS: -o outfile     (provide a name for the standalone executable)
         -c generated.c (leave the specified C file on the filesystem)
         -m mruby_dir   (provide the dir for mruby src)
         -b             (pregenerate ruby bytecode for faster execution)
         -v             (verbose)
EOF
      warn "  ERROR: #{msg}" if msg
      exit(msg ? USAGE_EXIT : 0)
    end

    def self.args(argv = ARGV)
      rb_files = []
      out_file = nil
      c_file = nil
      mruby_dir = nil
      verbose = false
      help = false
      bytecode = false

      while !argv.empty?
        arg = argv.shift
        if arg == '-o'
          out_file = argv.shift
          raise "no out_file provided with -o" unless out_file
          raise "#{out_file} is misnamed" if File.extname(out_file) == '.rb'
        elsif arg == '-c'
          c_file = File.open(argv.shift || 'generated.c', "w")
        elsif arg == '-v'
          verbose = true
        elsif arg == '-h'
          help = true
        elsif arg == '-m'
          mruby_dir = argv.shift
          raise "no mruby_dir provided with -m" unless mruby_dir
        elsif arg == '-b'
          bytecode = true
        else
          rb_files << arg unless arg == '--'
        end
      end

      c_file ||= Tempfile.new(['mrbt-', '.c'])
      out_file ||= 'outfile'

      { verbose: verbose,
        help: help,
        c_file: c_file,
        out_file: out_file,
        rb_files: rb_files,
        mruby_dir: mruby_dir,
        bytecode: bytecode }
    end
  end
end
