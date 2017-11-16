module MRubyTools
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

  def self.args(argv = ARGV)
    rb_files = []
    outfile = nil
    cfile = nil
    verbose = false
    help = false

    while !argv.empty?
      arg = argv.shift
      if arg == '-o'
        outfile = argv.shift
        raise "no outfile provided with -o" unless outfile
        raise "#{outfile} is misnamed" if File.extname(outfile) == '.rb'
      elsif arg == '-c'
        cfile = File.open(argv.shift || 'generated.c', "w")
      elsif arg == '-v'
        verbose = true
      elsif arg == '-h'
        help = true
      else
        rb_files << arg
      end
    end

    { verbose: verbose,
      help: help,
      cfile: cfile,
      outfile: outfile || 'outfile',
      rb_files: rb_files }
  end
end
