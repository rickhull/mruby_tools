require 'tempfile'

class MRubyTools
  class MRubyNotFound < RuntimeError; end

  MRUBY_VERSION = "1.3.0"
  MRUBY_URL = "https://github.com/mruby/mruby/archive/#{MRUBY_VERSION}.tar.gz"
  MRUBY_DIR = File.expand_path("../mruby-#{MRUBY_VERSION}", __dir__)

  def self.inc_path(mruby_dir = MRUBY_DIR)
    File.join(mruby_dir, 'include')
  end

  def self.ar_path(mruby_dir = MRUBY_DIR)
    File.join(mruby_dir, 'build', 'host', 'lib', 'libmruby.a')
  end

  attr_reader :mruby_dir, :mruby_inc, :mruby_ar

  def initialize(mruby_dir = nil)
    @mruby_dir = mruby_dir || MRUBY_DIR
    @mruby_inc = self.class.inc_path(@mruby_dir)
    raise(MRubyNotFound, @mruby_inc) unless File.directory? @mruby_inc
    @mruby_ar = self.class.ar_path(@mruby_dir)
    raise(MRubyNotFound, @mruby_ar) unless File.readable? @mruby_ar
  end

  def gcc_args(c_file, out_file)
    ['-std=c99', "-I", @mruby_inc, c_file, "-o", out_file, @mruby_ar, '-lm']
  end

  def compile(c_file, out_file)
    system('gcc', *self.gcc_args(c_file, out_file))
  end

  module C
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

    def self.slurp_rb(rb_filename, indent: '  ')
      c_str = File.read(rb_filename)
      size = c_str.size
      c_str = c_str.gsub("\n", '\n').gsub('"', '\"')
      c_str = File.read(rb_filename).gsub("\n", '\n').gsub('"', '\"')
      [ "/* #{rb_filename} */",
        'mrb_load_nstring(mrb, "' + c_str + '", ' + "#{size});",
        "check_exc(mrb, \"#{rb_filename}\");",
      ].map { |s| indent + s }.join("\n")
    end
  end

  module CLI
    def self.usage(msg = nil)
      puts <<EOF
  USAGE: mrbt file1.rb file2.rb ...
OPTIONS: -o outfile     (provide a name for the standalone executable)
         -c generated.c (leave the specified C file on the filesystem)
         -m mruby_dir   (provide the dir for mruby src)
         -v             (verbose)
EOF
      warn "  ERROR: #{msg}" if msg
      exit(msg ? 1 : 0)
    end

    def self.args(argv = ARGV)
      rb_files = []
      out_file = nil
      c_file = nil
      mruby_dir = nil
      verbose = false
      help = false

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
        else
          rb_files << arg
        end
      end

      c_file ||= Tempfile.new(['mrbt-', '.c'])

      { verbose: verbose,
        help: help,
        c_file: c_file,
        out_file: out_file || 'outfile',
        rb_files: rb_files,
        mruby_dir: mruby_dir }
    end
  end
end
