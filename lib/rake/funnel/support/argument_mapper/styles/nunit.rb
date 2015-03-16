module Rake
  module Funnel
    module Support
      module ArgumentMapper
        module Styles
          class NUnit
            attr_reader :prefix, :separator, :value_separator

            def initialize
              @prefix = Rake::Win32.windows? ? '/' : '-'
              @separator = '='
              @value_separator = ':'
            end

            def generate_from(model)
              model.map { |switch|
                switch.values.flatten.map { |value|
                  top_level(switch) + nested(value)
                }
              }.flatten(1)
            end

            private
            def top_level(switch)
              [prefix, switch.switch]
            end

            def nested(value)
              res = []
              res << separator unless value.key.nil? && value.value.nil?
              res << value.key
              res << value_separator unless value.key.nil? || value.value.nil?
              res << value.value
              res.compact
            end
          end
        end
      end
    end
  end
end
