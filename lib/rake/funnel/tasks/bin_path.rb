# frozen_string_literal: true

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

        def define(args, &task_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          desc 'Add local binaries to PATH environment variable' unless Rake.application.last_description

          task(name, *args) do |_, task_args|
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block

            next unless paths.any?

            prepend_pattern_to_path_environment(paths)
            $stderr.print "Added the following paths to the PATH environment variable:\n"
            paths.each do |p|
              $stderr.print "  - #{p}\n"
            end
          end

          self
        end

        def paths
          @paths ||= @path_modifier.call(Dir[*search_pattern].select { |path| File.directory?(path) })
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
