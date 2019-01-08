# frozen_string_literal: true

module Rake
  module Funnel
    module Support
      module ArgumentMapper
        class Value
          attr_reader :key, :value

          def initialize(value)
            @key = nil
            @value = value
          end
        end
      end
    end
  end
end
