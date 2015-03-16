module Rake
  module Funnel
    module Support
      module ArgumentMapper
        class Switch
          attr_reader :switch, :values

          def initialize(switch, values)
            @values = values
            @switch = switch
          end
        end
      end
    end
  end
end
