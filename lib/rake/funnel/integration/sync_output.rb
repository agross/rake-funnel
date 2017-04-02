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
        rescue => e
          Rake.rake_output_message "Failed to set up sync output #{e}"
        end
      end
    end
  end
end
