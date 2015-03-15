module Rake::Funnel::Support::ArgumentMapper
  class Switch
    attr_reader :switch, :values

    def initialize(switch, values)
      @values = values
      @switch = switch
    end
  end
end
