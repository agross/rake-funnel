# frozen_string_literal: true

module Rake
  module Funnel
    module Support
      module ArgumentMapper
        module Styles
          class MSBuild
            attr_reader :prefix, :separator, :value_separator

            def initialize
              @prefix = '/'
              @separator = ':'
              @value_separator = '='
            end

            def generate_from(model)
              model.flat_map do |switch|
                switch.values.flatten.map do |value|
                  top_level(switch) + nested(value)
                end
              end
            end

            private

            def top_level(switch)
              [prefix, switch.switch]
            end

            def nested(value) # rubocop:disable Metrics/AbcSize
              res = []
              res << separator unless value.key.nil? && value.value.nil?
              res << value.key
              res << value_separator unless value.key.nil? || value.value.nil?
              res << value.value
              res.compact
            end
          end
        end
      end
    end
  end
end
