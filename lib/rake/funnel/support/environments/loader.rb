require 'configatron'
require 'yaml'

module Rake
  module Funnel
    module Support
      module Environments
        class Loader
          class << self
            def load_configuration(config, store = configatron, customizer = nil)
              Rake.rake_output_message("Configuring for #{config[:name]}")
              store.unlock!
              store.reset!

              store.env = config[:name]
              load(config, store)

              customizer.call(store) if customizer && customizer.respond_to?(:call)

              store.lock!

              Rake.rake_output_message('')
              Rake.rake_output_message(store.inspect)
            end

            private

            def load(config, store)
              operation = 'Loading'
              config.fetch(:config_files, []).each do |file|
                Rake.rake_output_message("#{operation} #{file}")
                operation = 'Merging'

                yaml = File.read(file)
                yaml = evaluate_erb(yaml, file)
                yaml = YAML.load(yaml) || {} # rubocop:disable Security/YAMLLoad
                store.configure_from_hash(yaml)
              end
            end

            def evaluate_erb(yaml, filename)
              render = ERB.new(yaml)
              render.filename = filename
              render.result
            end
          end
        end
      end
    end
  end
end
