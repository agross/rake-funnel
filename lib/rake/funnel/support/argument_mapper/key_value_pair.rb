# frozen_string_literal: true

module Rake
  module Funnel
    module Support
      module ArgumentMapper
        class KeyValuePair
          attr_reader :key, :value

          def initialize(key, value)
            @key = key
            @value = value
          end
        end
      end
    end
  end
end
