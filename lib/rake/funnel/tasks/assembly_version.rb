require 'rake/tasklib'

module Rake::Funnel::Tasks
  class AssemblyVersion < Rake::TaskLib
    include Rake::Funnel::Support

    attr_accessor :name, :language, :source, :source_args, :target_path

    def initialize(*args, &task_block)
      setup_ivars(args)

      define(args, &task_block)
    end

    private
    def setup_ivars(args)
      @name = args.shift || :version

      @language = :cs
      @source = :FromVersionFiles
      @source_args = {}
      @target_path = next_to_version_file
    end

    def define(args, &task_block)
      desc 'Generate version info' unless Rake.application.last_description

      task(name, *args) do |_, task_args|
        task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block

        writer = AssemblyVersionWriter.new(source, source_args)
        writer.write(target_path, language)
      end
    end

    def next_to_version_file
      Proc.new { |language, _version_info, source| File.join(File.dirname(source), "VersionInfo.#{language}") }
    end
  end
end
