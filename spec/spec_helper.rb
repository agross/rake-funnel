require 'pipeline'

# When invoked via the rspec rake task, output needs to by synced.
Pipeline::Integration::SyncOutput.new

RSpec.configure do |config|
end
