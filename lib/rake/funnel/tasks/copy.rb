require 'rake/tasklib'

module Rake
  module Funnel
    module Tasks
      class Copy < Rake::TaskLib
        include Rake::Funnel::Support

        attr_accessor :name, :source, :target

        def initialize(*args, &task_block)
          setup_ivars(args)

          define(args, &task_block)
        end

        private

        def setup_ivars(args)
          @name = args.shift || :copy

          @source = []
          @target = nil
        end

        def define(args, &task_block)
          desc 'Copy files' unless Rake.application.last_description

          task(name, *args) do |_, task_args|
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block

            Copier.copy(files, target)
          end

          self
        end

        def files
          Finder.new(source, self, 'No files found.').all_or_default
        end
      end
    end
  end
end
