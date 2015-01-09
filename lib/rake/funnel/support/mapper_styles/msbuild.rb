module Rake::Funnel::Support::MapperStyles
  class MSBuild
    attr_reader :prefix, :separator, :value_separator

    def initialize
      @prefix = '/'
      @separator = ':'
      @value_separator = '='
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