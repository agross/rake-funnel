module Rake
  module Funnel
    module Support
      module ArgumentMapper
        module Styles
          class MSDeploy
            attr_reader :prefix, :separator, :value_separator, :value_list_separator

            def initialize
              @prefix = '-'
              @separator = ':'
              @value_separator = '='
              @value_list_separator = ','
            end

            def generate_from(model)
              model.map { |switch|
                switch.values.map { |item|
                  if item.is_a?(Enumerable)
                    values = item.map.with_index { |nested, index| nested(nested, index) }
                  else
                    values = nested(item)
                  end

                  (top_level(switch) + values).flatten
                }
              }.flatten(1)
            end

            private
            def top_level(switch)
              [prefix, quote(switch.switch)]
            end

            def nested(value, index = 0)
              res = []
              res << value_list_separator unless index == 0
              res << separator unless value.key.nil? && value.value.nil? || index != 0
              res << quote(value.key)
              res << value_separator unless value.key.nil? || value.value.nil?
              res << quote(value.value)
              res.compact
            end

            def quote(value)
              value = value.gsub(/"/, '""') if value.is_a?(String)
              return %{"#{value}"} if value =~ /\s/
              value
            end
          end
        end
      end
    end
  end
end
