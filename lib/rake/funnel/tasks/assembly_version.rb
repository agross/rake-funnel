# frozen_string_literal: true

require 'rake/tasklib'

module Rake
  module Funnel
    module Tasks
      class AssemblyVersion < Rake::TaskLib
        include Rake::Funnel::Support

        attr_accessor :name, :language, :source, :source_args, :target_path

        def initialize(*args, &task_block)
          setup_ivars(args)

          define(args, &task_block)
        end

        def next_to_source(language, _version_info, source)
          File.join(File.dirname(source), "VersionInfo.#{language}")
        end

        private

        def setup_ivars(args)
          @name = args.shift || :version

          @language = :cs
          @source = :FromVersionFiles
          @source_args = {}
          @target_path = proc do |language, version_info, source|
            next_to_source(language, version_info, source)
          end
        end

        def define(args, &task_block)
          desc 'Generate version info' unless Rake.application.last_description

          task(name, *args) do |_, task_args|
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block

            writer = AssemblyVersionWriter.new(source, source_args)
            writer.write(target_path, language)
          end
        end
      end
    end
  end
end
