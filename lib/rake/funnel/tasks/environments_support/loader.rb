require 'configatron'
require 'yaml'

module Rake::Funnel::Tasks::EnvironmentsSupport
  class Loader
    class << self
      def load_configuration(config, store = configatron)
        log("Configuring for #{config[:name]}")
        store.unlock!
        store.reset!

        store.env = config[:name]

        operation = 'Loading'
        config.fetch(:config_files, []).each do |file|
          log("#{operation} #{file}")
          operation = 'Merging'

          yaml = File.read(file)
          yaml = ERB.new(yaml).result
          yaml = YAML.load(yaml) || {}
          store.configure_from_hash(yaml)
        end

        store.lock!

        log('')
        log(store.inspect)
      end

      private
      def log(message)
        Rake.rake_output_message(message)
      end
    end
  end
end
