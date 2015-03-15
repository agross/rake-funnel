module Rake::Funnel::Support::ArgumentMapper
  class Value
    attr_reader :key, :value

    def initialize(value)
      @key = nil
      @value = value
    end
  end
end
