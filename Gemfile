require 'rbconfig'

source 'https://rubygems.org'

gemspec

group :development do
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-rubocop'

  case RbConfig::CONFIG['target_os']
  when /windows|bccwin|cygwin|djgpp|mingw|mswin|wince/i
    gem 'ruby_gntp'
    gem 'wdm'
  when /linux/i
    gem 'rb-inotify'
  when /mac|darwin/i
    gem 'rb-fsevent'
    gem 'growl'
  end
end

group :development, :ci do
  gem 'rspec', '~> 3.0'
  gem 'rspec-its'
  gem 'rspec-collection_matchers'
  gem 'coveralls'
  gem 'codeclimate-test-reporter'
  gem 'rubocop', '~> 0.46'
  gem 'rubocop-rspec'
  gem 'simplecov-teamcity-summary'
end
