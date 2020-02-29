# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :coverage do
  gem 'codeclimate-test-reporter'
  gem 'coveralls'
  gem 'simplecov-teamcity-summary'
end

group :style do
  gem 'rubocop', '< 0.50'
  gem 'rubocop-rspec'
end

group :test do
  gem 'rspec', '~> 3.0'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
end

group :guard do
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-rubocop'

  # guard notifications.
  install_if(-> { Gem.win_platform? }) do
    gem 'ruby_gntp'
    gem 'wdm'
  end

  install_if(-> { RbConfig::CONFIG['target_os'] =~ /linux/i }) do
    gem 'rb-inotify'
  end

  install_if(-> { RbConfig::CONFIG['target_os'] =~ /mac|darwin/i }) do
    gem 'rb-fsevent'
    gem 'terminal-notifier-guard'
  end
end
