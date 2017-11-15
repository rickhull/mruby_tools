Gem::Specification.new do |s|
  s.name = 'mruby_tools'
  s.summary = "MRI Ruby tools for assisting in MRuby development"
  s.description = "TBD"
  s.authors = ["Rick Hull"]
  s.homepage = "https://github.com/rickhull/mruby-tools"
  s.license = "LGPL-3.0"

  s.required_ruby_version = "~> 2"

  s.version = File.read(File.join(__dir__, 'VERSION')).chomp

  s.files = %w[mruby_tools.gemspec VERSION README.md Rakefile]
  %w[lib bin test examples].each { |dir|
    s.files += Dir[File.join(dir, '**', '*.rb')]
  }

  s.add_development_dependency "rake", "~> 0"
  s.add_development_dependency "buildar", "~> 3.0"
#  s.add_development_dependency "minitest", "~> 5.0"
#  s.add_development_dependency "flog", "~> 0"
#  s.add_development_dependency "flay", "~> 0"
#  s.add_development_dependency "roodi", "~> 0"
#  s.add_development_dependency "ruby-prof", "~> 0"
#  s.add_development_dependency "benchmark-ips", "~> 2.0"
end
