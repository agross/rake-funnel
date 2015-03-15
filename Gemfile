require 'rbconfig'

source 'https://rubygems.org'

gemspec

group :development do
  gem 'guard-bundler', require: false
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false

  case RbConfig::CONFIG['target_os']
  when /windows|bccwin|cygwin|djgpp|mingw|mswin|wince/i
    gem 'ruby_gntp', require: false
    gem 'wdm', require: false
  when /linux/i
    gem 'rb-inotify', require: false
  when /mac|darwin/i
    gem 'rb-fsevent', require: false
    gem 'growl', require: false
  end
end

group :development, :ci do
  gem 'rspec', '~> 3.0', require: false
  gem 'rspec-its', require: false
  gem 'rspec-collection_matchers', require: false
  gem 'coveralls', require: false
  gem 'codeclimate-test-reporter', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end
