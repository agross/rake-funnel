module Rake
  module Funnel
    module Support
      module ArgumentMapper
        module Styles
          class Default
            attr_reader :prefix, :value_separator

            def initialize
              @prefix = '/'
              @value_separator = ','
            end

            def generate_from(model)
              model.map do |switch|
                switch.values.flatten.map do |value|
                  [top_level(switch), nested(value)].reject(&:empty?)
                end
              end.flatten(2)
            end

            private

            def top_level(switch)
              [prefix, switch.switch]
            end

            def nested(value)
              res = []
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
