module Rake::Funnel::Support::ArgumentMapper
  class KeyValuePair
    attr_reader :key, :value

    def initialize(key, value)
      @key = key
      @value = value
    end
  end
end
