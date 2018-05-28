module Rake
  module Funnel
    module Integration
      class SyncOutput
        def initialize
          sync($stdout)
          sync($stderr)
        end

        private

        def sync(stream)
          stream.sync = true
        rescue => e # rubocop:disable Style/RescueStandardError
          $stderr.print "Failed to set up sync output #{e}\n"
        end
      end
    end
  end
end
