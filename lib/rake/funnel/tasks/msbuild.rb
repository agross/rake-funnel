require 'rake/tasklib'

Dir["#{File.dirname(__FILE__)}/msbuild_support/*.rb"].each do |path|
  require path
end

module Rake::Funnel::Tasks
  class MSBuild < Rake::TaskLib
    attr_accessor :name, :project_or_solution, :args, :search_pattern

    def initialize(name = :compile)
      @name = name
      @args = {}
      @search_pattern = %w(**/*.sln)

      yield self if block_given?
      define
    end

    def msbuild
      @_msbuild || MSBuildSupport::BuildTool.find
    end

    def msbuild=(value)
      @_msbuild = value
    end

    def project_or_solution
      @_project_or_solution || search_sln
    end

    def project_or_solution=(value)
      @_project_or_solution = value
    end

    private
    def define
      desc "Compile #{project_or_solution}"
      task @name do
        if project_or_solution.nil?
          raise Rake::Funnel::AmbiguousFileError.new('No projects or more than one project found.', @name, @search_pattern, candidates)
        end

        cmd = [
          msbuild,
          project_or_solution,
          *Rake::Funnel::Support::Mapper.new(:MSBuild).map(args)
        ]

        shell(cmd)
      end

      self
    end

    def search_sln
      return candidates.first if candidates.one?

      nil
    end

    def candidates
      Dir.glob(@search_pattern).select { |f| File.file?(f) }
    end
  end
end
