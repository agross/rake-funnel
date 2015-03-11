Dir[File.join(File.dirname(__FILE__), 'argument_mapper', '*.rb')].each do |path|
  require path
end

module Rake::Funnel::Support
  class Mapper
    include Rake::Funnel::Support::ArgumentMapper

    def initialize(style = :Default)
      raise "You cannot use a 'nil' mapper. Available mappers are: #{Styles.constants.sort.join(', ')}" if style.nil?

      @style = style
      begin
        @style = Styles.const_get(style).new if style.kind_of?(Symbol)
      rescue => ex
        raise "Something went wrong while creating the '#{style}' mapper: #{ex}"
      end
    end

    def map(args = {})
      model = (args || {}).map { |switch, value|
        value = [value] unless value.kind_of?(Array)

        values = value.map do |val|
          get_values(val)
        end

        Switch.new(switch, values)
      }.flatten

      @style
        .generate_from(model)
        .map { |args| args.map { |arg| camel_case_symbols(arg) }}
        .map(&:join)
    end

    private
    def get_values(value)
      if value.kind_of?(Enumerable)
        pairs = value.map { |k, v|
          KeyValuePair.new(k, v)
        }

        return Array.new(pairs) if value.kind_of?(Array)
        pairs
      else
        Value.new(value)
      end
    end

    def camel_case_symbols(value)
      return value unless value.kind_of?(Symbol)
      value.camelize
    end
  end
end
