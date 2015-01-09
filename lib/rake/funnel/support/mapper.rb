Dir["#{File.dirname(__FILE__)}/mapper_styles/*.rb"].each do |path|
  require path
end

module Rake::Funnel::Support
  class Switch
    attr_reader :switch, :values

    def initialize(switch, values)
      @values = values
      @switch = switch
    end
  end

  class Value
    attr_reader :key, :value

    def initialize(value)
      @key = nil
      @value = value
    end
  end

  class KeyValuePair
    attr_reader :key, :value

    def initialize(key, value)
      @key = key
      @value = value
    end
  end

  class Mapper
    def initialize(style = :Default)
      raise "You cannot use a 'nil' mapper. Available mappers are: #{MapperStyles.constants.sort.join(', ')}" if style.nil?

      @style = style
      begin
        @style = MapperStyles.const_get(style).new if style.kind_of?(Symbol)
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
