require 'rake/tasklib'

module Rake::Funnel::Tasks
  class MSBuild < Rake::TaskLib
    include Rake::Funnel::Support
    include Rake::Funnel::Support::MSBuild

    attr_accessor :name, :project_or_solution, :args, :search_pattern

    def initialize(name = :compile)
      @name = name
      @args = {}
      @search_pattern = %w(**/*.sln)

      yield self if block_given?
      define
    end

    def msbuild
      @_msbuild || BuildTool.find
    end

    def msbuild=(value)
      @_msbuild = value
    end

    def project_or_solution
      Finder.new(@_project_or_solution || search_pattern, self, 'No projects or more than one project found.')
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
          *Mapper.new(:MSBuild).map(args)
        ]

        sh(*cmd)
      end

      self
    end
  end
end
