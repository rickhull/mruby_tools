require 'tempfile'

module MRubyTools
  def self.c_wrapper(rb_files)
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
      "\n" + self.rb2c(rbf) + "\n\n"
    }.join

    c_code += <<EOF
  mrb_close(mrb);
  return 0;
}
EOF
    c_code
  end

  def self.rb2c(rb_filename, indent: '  ')
    c_str = File.read(rb_filename)
    size = c_str.size
    c_str = c_str.gsub("\n", '\n').gsub('"', '\"')
    c_str = File.read(rb_filename).gsub("\n", '\n').gsub('"', '\"')
    [ "/* #{rb_filename} */",
      'mrb_load_nstring(mrb, "' + c_str + '", ' + "#{size});",
      "check_exc(mrb, \"#{rb_filename}\");",
    ].map { |s| indent + s }.join("\n")
  end

  def self.mruby_src_dir(env_var = 'MRUBY_SRC')
    mruby_src_dir = ENV[env_var]
    raise "env: MRUBY_SRC is required" unless mruby_src_dir
    raise "bad MRUBY_SRC #{mruby_src_dir}" unless File.directory? mruby_src_dir
    mruby_inc_dir = File.join(mruby_src_dir, 'include')
    raise "bad MRUBY_SRC #{mruby_inc_dir}" unless File.directory? mruby_inc_dir
    mruby_src_dir
  end

  def self.usage(msg = nil)
    puts <<EOF
  USAGE: mrbt file1.rb file2.rb ...
OPTIONS: -o outfile     (provide a name for the standalone executable)
         -c generated.c (leave the specified C file on the filesystem)
         -v             (verbose)
EOF
    warn "  ERROR: #{msg}" if msg
    exit
  end

  def self.args(argv = ARGV)
    rb_files = []
    out_file = nil
    c_file = nil
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
      else
        rb_files << arg
      end
    end

    c_file ||= Tempfile.new(['generated', '.c'])

    { verbose: verbose,
      help: help,
      c_file: c_file,
      out_file: out_file || 'outfile',
      rb_files: rb_files }
  end
end
