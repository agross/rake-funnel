# frozen_string_literal: true

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

        def initialize(style = :default)
          raise "You cannot use the 'nil' mapper style. Available mappers are: #{available.inspect}" if style.nil?

          @style = create(style)
        end

        def map(args = {}) # rubocop:disable Metrics/MethodLength
          model = (args || {}).map do |switch, value|
            value = [value] unless value.is_a?(Array)

            values = value.map do |val|
              get_values(val)
            end

            Switch.new(switch, values)
          end.flatten

          @style
            .generate_from(model)
            .map { |arguments| arguments.map { |arg| camel_case_symbols(arg) } }
            .map(&:join)
        end

        private

        def get_values(value)
          if value.is_a?(Enumerable)
            pairs = value.map do |k, v|
              KeyValuePair.new(k, v)
            end

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
