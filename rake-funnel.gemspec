lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rake/funnel/version'

Gem::Specification.new do |s|
  s.name        = 'rake-funnel'
  s.version     = Rake::Funnel::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Alexander Groß']
  s.email       = ['agross@therightstuff.de']
  s.homepage    = 'http://grossweber.com'
  s.license     = 'BSD'
  s.description = %q{A standardized build pipeline}
  s.summary     = %q{The build pipeline}

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency 'rake'
  s.add_dependency 'rubyzip', '~> 1.0'
  s.add_dependency 'smart_colored'

  git = ENV['TEAMCITY_GIT_PATH'] || 'git'
  s.files         = `"#{git}" ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']
end
