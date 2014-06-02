require 'rspec/its'
require 'rspec/collection_matchers'
require 'rake/funnel'

# When invoked via the rspec rake task, output needs to by synced.
Rake::Funnel::Integration::SyncOutput.new

RSpec.configure do |config|
  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
