require 'rake/testtask'
require_relative './lib/mruby_tools.rb'

#
# GET / SETUP MRUBY
#

mrb = MRubyTools.new

file mrb.ar_path do
  if mrb.src?
    Dir.chdir MRubyTools.mruby_dir do
      sh "make"
    end
  end
  mrb.validate!
end


#
# lib/mruby_tools tests
#

Rake::TestTask.new :test do |t|
  t.pattern = "test/*.rb"
  t.warning = true
end


#
# run mrbt via `rake mrbt`
#

@verbose = false

task :verbose do
  @verbose = true
end

@bytecode = false

task :bytecode do
  @bytecode = true
end

def mrbt *args
  args.unshift('-v') if @verbose and !args.include?('-v')
  args.unshift('-b') if @bytecode and !args.include?('-b')
  ruby '-Ilib', 'bin/mrbt', *args
end

task mrbt: mrb.ar_path do
  # consume ARGV
  args = []
  found_mrbt = false
  while !ARGV.empty?
    arg = ARGV.shift
    # skip all args until we reach 'mrbt'
    if found_mrbt
      args << arg
      next
    end
    found_mrbt = true if arg == 'mrbt'
  end
  begin
    mrbt *args
  rescue RuntimeError
    exit 1
  end
end


#
# mrbt EXAMPLES
#

def run_clean execfile, clean: true
  begin
    if @verbose
      puts
      sh "file", execfile
      puts
      sh "stat", execfile
      puts
    end
    sh execfile
  ensure
    if clean
      File.unlink execfile unless @verbose
    end
  end
end

desc "Run hello_world example"
task hello_world: mrb.ar_path do
  execfile = "examples/hello_world"
  mrbt "examples/hello_world.rb", "-o", execfile
  run_clean execfile
end

desc "Run timed_simplex example"
task timed_simplex: mrb.ar_path do
  execfile = "examples/timed_simplex"
  mrbt "examples/timer.rb", "examples/simplex.rb", "examples/driver.rb",
       "-o", execfile
  run_clean execfile
end

desc "Run raise example"
task raise_exception: mrb.ar_path do
  execfile = "examples/raise"
  mrbt "examples/hello_world.rb", "examples/raise.rb", "-o", execfile
  run_clean execfile
end

desc "Run examples"
task examples: [:hello_world, :timed_simplex]

task default: [:test, :examples]

#
# METRICS
#

begin
  require 'flog_task'
  FlogTask.new do |t|
    t.dirs = ['lib']
    t.verbose = true
  end
rescue LoadError
  warn 'flog_task unavailable'
end

begin
  require 'flay_task'
  FlayTask.new do |t|
    t.dirs = ['lib']
    t.verbose = true
  end
rescue LoadError
  warn 'flay_task unavailable'
end

begin
  require 'roodi_task'
  # RoodiTask.new config: '.roodi.yml', patterns: ['lib/**/*.rb']
  RoodiTask.new patterns: ['lib/**/*.rb']
rescue LoadError
  warn "roodi_task unavailable"
end

#
# GEM BUILD / PUBLISH
#

begin
  require 'buildar'

  Buildar.new do |b|
    b.gemspec_file = 'mruby_tools.gemspec'
    b.version_file = 'VERSION'
    b.use_git = true
  end
rescue LoadError
  warn "buildar tasks unavailable"
end
