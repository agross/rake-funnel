$:.push File.expand_path('../lib', __FILE__)
require 'rbconfig'
require 'pipeline/version'

Gem::Specification.new do |s|
  s.name        = 'pipeline'
  s.version     = Pipeline::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Alexander Groß']
  s.email       = ['agross@therightstuff.de']
  s.homepage    = 'http://grossweber.com'
  s.licenses    = ['BSD']
  s.description = %q{A standardized build pipeline}
  s.summary     = %q{The build pipeline}

  s.add_dependency 'rake'
  s.add_dependency 'smart_colored'

  s.add_development_dependency 'rspec', '>= 3.0.0beta2'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'rspec-collection_matchers'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-bundler'

  case RbConfig::CONFIG['target_os']
  when /windows|bccwin|cygwin|djgpp|mingw|mswin|wince/i
    s.add_development_dependency 'ruby_gntp'
    s.add_development_dependency 'wdm'
  when /linux/i
    s.add_development_dependency 'rb-inotify'
  when /mac|darwin/i
    s.add_development_dependency 'rb-fsevent'
    s.add_development_dependency 'growl'
  end

  git = ENV['TEAMCITY_GIT_PATH'] || 'git'
  s.files         = `"#{git}" ls-files`.split("\n")
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.executables   = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
