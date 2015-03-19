module Rake
  module Funnel
    module Support
      class Trace
        class << self
          def message(message)
            return unless Rake.application.options.trace

            Rake.rake_output_message(message)
          end
        end
      end
    end
  end
end
