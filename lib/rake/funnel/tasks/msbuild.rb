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
      Rake::Funnel::Support::Finder.new(@_project_or_solution || search_pattern, self, 'No projects or more than one project found.')
    end

    def project_or_solution=(value)
      @_project_or_solution = value
    end

    private
    def define
      desc "Compile #{project_or_solution.single_or_default}"
      task @name do
        cmd = [
          msbuild,
          project_or_solution.single,
          *Rake::Funnel::Support::Mapper.new(:MSBuild).map(args)
        ]

        sh(*cmd)
      end

      self
    end
  end
end
