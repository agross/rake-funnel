require 'rspec/its'
require 'rspec/collection_matchers'
require 'simplecov'
require 'bundler/setup'

require 'rake/funnel'

# Try to load registry so we can check in specs whether it's defined.
begin
  require 'win32/registry'
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

# When invoked via the rspec rake task, output needs to by synced.
Rake::Funnel::Integration::SyncOutput.new

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
