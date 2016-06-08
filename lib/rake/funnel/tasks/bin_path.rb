require 'rake/tasklib'

module Rake
  module Funnel
    module Tasks
      class BinPath < Rake::TaskLib
        attr_accessor :name, :search_pattern, :path_modifier

        def initialize(*args, &task_block)
          setup_ivars(args)

          define(args, &task_block)
        end

        private
        def setup_ivars(args)
          @name = args.shift || :bin_path
          @search_pattern = %w(tools/* tools/*/bin packages/**/tools)
          @path_modifier = proc { |paths| paths }
        end

        def define(args, &task_block)
          desc 'Add local binaries to PATH environment variable' unless Rake.application.last_description

          task(name, *args) do |_, task_args|
            task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block

            next unless paths.any?

            prepend_pattern_to_path_environment(paths)
            Rake.rake_output_message 'Added the following paths to the PATH environment variable:'
            paths.each do |p|
              Rake.rake_output_message "  - #{p}"
            end
          end

          self
        end

        def paths
          @paths ||= @path_modifier.call(Dir[*search_pattern])
                                   .map { |path| File.expand_path(path) }
                                   .sort
        end

        def prepend_pattern_to_path_environment(paths)
          ENV['PATH'] = ([] << paths << ENV['PATH']).flatten.join(File::PATH_SEPARATOR)
          paths
        end
      end
    end
  end
end
