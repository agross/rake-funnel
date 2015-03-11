require 'rake/tasklib'

module Rake::Funnel::Tasks
  class NUnit < Rake::TaskLib
    include Rake::Funnel::Support

    attr_accessor :name, :files, :args

    def initialize(name = :test)
      @name = name
      @args = {}
      @files = %w(build/specs/**/*.dll build/specs/**/*.exe)

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
          *Mono.invocation(nunit),
          *test_assemblies.all,
          *Mapper.new(:NUnit).map(args)
        ]

        sh(*cmd)
      end

      self
    end

    def test_assemblies
      Finder.new(files, self, 'No test assemblies found.')
    end
  end
end
