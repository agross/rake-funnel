# frozen_string_literal: true

module Rake
  module Funnel
    module Integration
      module TeamCity
        class ServiceMessages
          class << self
            def respond_to_missing?(_method, _include_private = false)
              true
            end

            def method_missing(method, *args, &_block) # rubocop:disable Style/MethodMissingSuper
              return unless Rake::Funnel::Integration::TeamCity.running?

              message_name = method.camelize
              publish(message_name, args[0])
            end

            private

            def publish(message_name, args)
              args = [message_name] << escaped_array_of(args)
              args = args.flatten.reject(&:nil?)

              print "##teamcity[#{args.join(' ')}]\n"
            end

            def escape(string) # rubocop:disable Metrics/MethodLength
              string
                .to_s
                .gsub(/\|/, '||')
                .gsub(/'/, "|'")
                .gsub(/\r/, '|r')
                .gsub(/\n/, '|n')
                .gsub(/\u0085/, '|x')
                .gsub(/\u2028/, '|l')
                .gsub(/\u2029/, '|p')
                .gsub(/\[/, '|[')
                .gsub(/\]/, '|]')
            end

            def escaped_array_of(args)
              return [] if args.nil?

              return "'#{escape(args)}'" unless args.is_a?(Hash)

              args.map { |key, value| "#{key.camelize}='#{escape(value.to_s)}'" }
            end
          end
        end
      end
    end
  end
end
