require 'rake/testtask'

Rake::TestTask.new :test do |t|
  t.pattern = "test/*.rb"
  t.warning = true
end

desc "Run timed_simplex example"
task :timed_simplex do |t|
  ruby "-Ilib bin/mrbt examples/timer.rb examples/simplex.rb " +
     "examples/driver.rb -o examples/timed_simplex -v"
end

desc "Run examples"
task examples: [:timed_simplex]

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
