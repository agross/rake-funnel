module Rake
  module Funnel
    module Support
      class Trace
        class << self
          def message(message)
            return unless Rake.application.options.trace

            $stderr.print("#{message}\n")
          end
        end
      end
    end
  end
end
