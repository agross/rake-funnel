module Rake
  module Funnel
    module Integration
      class SyncOutput
        def initialize
          $stdout.sync = true
          $stderr.sync = true
        end
      end
    end
  end
end
