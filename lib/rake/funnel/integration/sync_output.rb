module Rake::Funnel::Integration
  class SyncOutput
    def initialize
      $stdout.sync = true
      $stderr.sync = true
    end
  end
end
