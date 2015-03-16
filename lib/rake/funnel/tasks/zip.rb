require 'rake/tasklib'

module Rake
  module Funnel
    module Tasks
      class Zip < Rake::TaskLib
        include Rake::Funnel::Support

        attr_accessor :name, :source, :target, :zip_root

        def initialize(*args, &task_block)
          setup_ivars(args)

          define(args, &task_block)
        end

        private
        def setup_ivars(args)
          @name = args.shift || :package

          @source = []
          @target = nil
          @zip_root = nil
        end

        def define(args, &task_block)
          desc 'Zip files' unless Rake.application.last_description

          task(name, *args) do |_, task_args|
            task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block

            Zipper.zip(files, target, zip_root)

            Rake.rake_output_message("Created #{target}")
          end

          self
        end

        def files
          Finder.new(source, self, 'No files to zip.').all_or_default
        end
      end
    end
  end
end
