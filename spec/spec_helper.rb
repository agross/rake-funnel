require 'rspec/its'
require 'rspec/collection_matchers'
require 'rake/funnel'
require 'coveralls'

Coveralls.wear! if Coveralls.will_run?

# When invoked via the rspec rake task, output needs to by synced.
Rake::Funnel::Integration::SyncOutput.new

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
