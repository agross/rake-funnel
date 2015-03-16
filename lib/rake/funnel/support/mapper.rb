Dir[File.join(File.dirname(__FILE__), 'argument_mapper', '*.rb')].each do |path|
  require path
end

module Rake
  module Funnel
    module Support
      class Mapper
        include ArgumentMapper
        include InstantiateSymbol
        instantiate Styles

        def initialize(style = :Default)
          raise "You cannot use the 'nil' mapper style. Available mappers are: #{available.inspect}" if style.nil?

          @style = create(style)
        end

        def map(args = {})
          model = (args || {}).map { |switch, value|
            value = [value] unless value.is_a?(Array)

            values = value.map do |val|
              get_values(val)
            end

            Switch.new(switch, values)
          }.flatten

          @style
            .generate_from(model)
            .map { |args| args.map { |arg| camel_case_symbols(arg) } }
            .map(&:join)
        end

        private
        def get_values(value)
          if value.is_a?(Enumerable)
            pairs = value.map { |k, v|
              KeyValuePair.new(k, v)
            }

            return Array.new(pairs) if value.is_a?(Array)
            pairs
          else
            Value.new(value)
          end
        end

        def camel_case_symbols(value)
          return value unless value.is_a?(Symbol)
          value.camelize
        end
      end
    end
  end
end
