#!/usr/bin/env ruby

require 'tempfile'

# args like: file1.rb file2.rb -o outfile
#  possibly: file1.rb -o outfile file2.rb -c generated.c

rb_files = []
outfile = nil
cfile = nil
verbose = false

while !ARGV.empty?
  arg = ARGV.shift
  if arg == '-o'
    outfile = ARGV.shift
    raise "no outfile provided with -o" unless outfile
    raise "#{outfile} is misnamed" if File.extname(outfile) == '.rb'
  elsif arg == '-c'
    cfile = File.open(ARGV.shift || 'generated.c', "w")
  elsif arg == '-v'
    verbose = true
  else
    rb_files << arg
  end
end
outfile ||= 'outfile'

if verbose
  puts "rb_files: #{rb_files.join(', ')}"
  puts " outfile: #{outfile}"
  puts "   cfile: #{File.basename(cfile)}" if cfile
  puts " verbose: #{verbose}"
  puts "---"
end

mruby_src_dir = ENV['MRUBY_SRC']
raise "env: MRUBY_SRC is required" unless mruby_src_dir
raise "bad MRUBY_SRC #{mruby_src_dir}" unless File.directory? mruby_src_dir
mruby_inc_dir = File.join(mruby_src_dir, 'include')
raise "bad MRUBY_SRC #{mruby_inc_dir}" unless File.directory? mruby_inc_dir

def rb2c(rb_filename, indent: '  ')
  c_str = File.read(rb_filename)
  size = c_str.size
  c_str = c_str.gsub("\n", '\n').gsub('"', '\"')
  c_str = File.read(rb_filename).gsub("\n", '\n').gsub('"', '\"')
  [ "/* #{rb_filename} */",
    'mrb_load_nstring(mrb, "' + c_str + '", ' + "#{size});",
    "check_exc(mrb, \"#{rb_filename}\");",
  ].map { |s| indent + s }.join("\n")
end

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

  c_code += rb_files.map { |rbf| "\n" +  rb2c(rbf) + "\n\n" }.join

  c_code += <<EOF
  mrb_close(mrb);
  return 0;
}
EOF

puts c_code + "\n" if verbose

file = cfile || Tempfile.new(['generated', '.c'])
file.write(c_code)
file.close

gcc_args = ['-std=c99', "-I", mruby_inc_dir, file.path, "-o", outfile,
            File.join(mruby_src_dir, 'build', 'host', 'lib', 'libmruby.a'),
            '-lm']

puts "compiling..."
if system('gcc', *gcc_args)
  puts "created binary executable: #{outfile}"
end
