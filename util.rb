#!/usr/bin/env ruby

require 'tempfile'

# args like: file1.rb file2.rb -o outfile
#  possibly: file1.rb -o outfile file2.rb -c generated.c

rb_files = []
outfile = nil
cfile = nil

while !ARGV.empty?
  arg = ARGV.shift
  if arg == '-o'
    outfile = ARGV.shift
    raise "no outfile provided with -o" unless outfile
    raise "#{outfile} is misnamed" if File.extname(outfile) == '.rb'
  elsif arg == '-c'
    cfile = File.open(ARGV.shift || 'generated.c', "w")
  else
    rb_files << arg
  end
end

raise "-o outfile is required" unless outfile

mruby_src_dir = ENV['MRUBY_SRC']
raise "env: MRUBY_SRC is required" unless mruby_src_dir
raise "bad MRUBY_SRC #{mruby_src_dir}" unless File.directory? mruby_src_dir
mruby_inc_dir = File.join(mruby_src_dir, 'include')
raise "bad MRUBY_SRC #{mruby_inc_dir}" unless File.directory? mruby_inc_dir

def rb2c(rb_filename)
  c_str = File.read(rb_filename).gsub("\n", '\n').gsub('"', '\"')
  'mrb_load_nstring(mrb, "' + c_str + '", ' + "#{c_str.size});\n"
end

c_code = <<EOF
#include <stdlib.h>
#include <mruby.h>
#include <mruby/compile.h>

int
main(void)
{
  mrb_state *mrb = mrb_open();
  if (!mrb) {
    printf("mrb problem");
    exit(1);
  }
EOF

rb_files.each { |rbf|
  c_code += "\n  /* #{rbf} */\n"
  c_code += '  ' + rb2c(rbf) + "\n"
}

c_code += <<EOF
  mrb_close(mrb);
  return 0;
}
EOF

# puts c_code + "\n"

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
