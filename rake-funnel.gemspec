# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rake/funnel/version'

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name        = 'rake-funnel'
  s.version     = Rake::Funnel::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Alexander Groß']
  s.email       = ['agross@therightstuff.de']
  s.homepage    = 'http://grossweber.com'
  s.license     = 'BSD-3-Clause'
  s.description = 'A standardized build pipeline'
  s.summary     = 'A build pipeline targeted at .NET projects. Supports environment configuration and makes invoking .NET-related tasks easier.' # rubocop:disable Metrics/LineLength

  # We support Ruby 2.0 whereas rubocop does not.
  s.required_ruby_version = '>= 2.0.0' # rubocop:disable Gemspec/RequiredRubyVersion

  s.add_dependency 'configatron', '~> 4.5'
  s.add_dependency 'rake', '>= 10.4', '< 13'
  s.add_dependency 'rubyzip', '~> 1.0'
  s.add_dependency 'smart_colored'

  git = ENV['TEAMCITY_GIT_PATH'] || 'git'
  files = `"#{git}" ls-files -z`
          .split("\x0")
          .reject do |file|
    file =~ %r{^(config/|tools/|lib/tasks)} ||
      file =~ /\.git|\.travis|\.ruby-version|\.rubocop/ ||
      file =~ /(Guard|Rake)file/ ||
      File.extname(file) == '.cmd'
  end

  s.files         = files
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']
end
