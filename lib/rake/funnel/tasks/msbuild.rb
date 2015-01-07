require 'rake/tasklib'

module Rake::Funnel::Tasks
  class MSBuild < Rake::TaskLib
    attr_accessor :name, :clr_version, :project_or_solution, :args, :search_pattern

    def initialize(name = :compile)
      @name = name
      @clr_version = 'v4.0.30319'
      @args = {}
      @search_pattern = %w(**/*.sln)

      yield self if block_given?
      define
    end

    def msbuild
      @_msbuild || File.join('C:/Windows/Microsoft.NET/Framework/', @clr_version, 'msbuild.exe')
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

        mapper = Rake::Funnel::Support::Mapper.new(:MSBuild)
        cmd = [msbuild, project_or_solution, mapper.map(args)].flatten.reject(&:nil?)

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
