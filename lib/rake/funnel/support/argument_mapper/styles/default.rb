module Rake::Funnel::Support::ArgumentMapper::Styles
  class Default
    attr_reader :prefix, :value_separator

    def initialize
      @prefix = '/'
      @value_separator = ','
    end

    def generate_from(model)
      model.map { |switch|
        switch.values.flatten.map { |value|
          [top_level(switch), nested(value)].reject(&:empty?)
        }
      }.flatten(2)
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
