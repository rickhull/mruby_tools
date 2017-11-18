require 'rake/testtask'
require_relative './lib/mruby_tools.rb'

Rake::TestTask.new :test do |t|
  t.pattern = "test/*.rb"
  t.warning = true
end

#
# GET / SETUP MRUBY
#

makefile = File.join(MRubyTools::MRUBY_DIR, 'Makefile')
ar_path = MRubyTools.ar_path

file makefile do
  sh "curl -L #{MRubyTools::MRUBY_URL} | tar xz"
end

file ar_path => makefile do
  Dir.chdir MRubyTools::MRUBY_DIR do
    sh "make"
  end
end

#
# mrbt EXAMPLES
#

@verbose = false

def mrbt *args
  ruby '-Ilib', 'bin/mrbt', *args
end

def runout outfile
  if @verbose
    puts
    sh "file", outfile
    puts
    sh "stat", outfile
    puts
  end
  sh outfile
end

task :verbose do
  @verbose = true
end

desc "Run hello_world example"
task hello_world: ar_path do
  outfile = "examples/hello_world"
  args = ["examples/hello_world.rb", "-o", outfile]
  args << '-v' if @verbose
  mrbt *args
  begin
    runout outfile
  ensure
    File.unlink outfile unless @verbose
  end
end

desc "Run timed_simplex example"
task timed_simplex: ar_path do
  outfile = "examples/timed_simplex"
  args = ['examples/timer.rb', 'examples/simplex.rb', 'examples/driver.rb',
          '-o', outfile]
  args << '-v' if @verbose
  mrbt *args
  begin
    runout outfile
  ensure
    File.unlink outfile unless @verbose
  end
end

desc "Run raise example"
task raise_exception: ar_path do
  outfile = "examples/raise"
  args = ["examples/hello_world.rb", "examples/raise.rb", "-o", outfile]
  args << '-v' if @verbose
  mrbt *args
  begin
    runout outfile
  ensure
    File.unlink outfile unless @verbose
  end
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
