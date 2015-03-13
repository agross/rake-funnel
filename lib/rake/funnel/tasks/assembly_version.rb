require 'rake/tasklib'

module Rake::Funnel::Tasks
  class AssemblyVersion < Rake::TaskLib
    include Rake::Funnel::Support

    attr_accessor :name, :language, :source, :source_args, :target_path

    def initialize(name = :version)
      @name = name
      @language = :cs
      @source = :FromVersionFiles
      @source_args = {}
      @target_path = next_to_version_file

      yield self if block_given?
      define
    end

    private
    def define
      desc 'Generate version info'
      task name do
        writer = AssemblyVersionWriter.new(source, source_args)

        writer.write(target_path, language)
      end
    end

    def next_to_version_file
      Proc.new { |language, version_info, source| File.join(File.dirname(source), "VersionInfo.#{language}") }
    end
  end
end
