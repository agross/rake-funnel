require 'rake/tasklib'

module Rake::Funnel::Tasks
  class MSBuild < Rake::TaskLib
    attr_accessor :name, :clr_version, :project_or_solution, :switches, :properties, :search_pattern

    def initialize(name = :compile)
      @name = name
      @clr_version = 'v4.0.30319'
      @switches = {}
      @properties = {}
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

        cmd = [msbuild, project_or_solution, map_switches, map_properties].flatten.reject(&:nil?)

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

    def map_switches
      (@switches || {}).map { |key, value|
        v = ":#{value}" unless value.kind_of? TrueClass or value.kind_of? FalseClass
        "/#{key}#{v}" if value
      }
    end

    def map_properties
      (@properties || {}).map { |key, value|
        v = "=#{value}" unless value.kind_of? TrueClass or value.kind_of? FalseClass
        "/property:#{key}#{v}" if value
      }
    end
  end
end
