require 'rake/tasklib'

module Rake::Funnel::Tasks
  class NUnit < Rake::TaskLib
    attr_accessor :name, :search_pattern, :args

    def initialize(name = :test)
      @name = name
      @args = {}
      @search_pattern = %w(build/specs/**/*.dll build/specs/**/*.exe)

      yield self if block_given?
      define
    end

    def nunit
      @_nunit || 'nunit-console.exe'
    end

    def nunit=(value)
      @_nunit = value
    end

    private
    def define
      desc "Test #{test_assemblies.all_or_default.join(', ')}"
      task name do
        Rake::Funnel::Integration::TeamCity::NUnitPlugin.setup(nunit)

        cmd = [
          *Rake::Funnel::Support::Mono.invocation(nunit),
          *test_assemblies.all,
          *Rake::Funnel::Support::Mapper.new(:NUnit).map(args)
        ]

        sh(*cmd)
      end

      self
    end

    def test_assemblies
      Rake::Funnel::Support::Finder.new(search_pattern, self, 'No test assemblies found.')
    end
  end
end
