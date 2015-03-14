require 'rake/tasklib'

module Rake::Funnel::Tasks
  class NUnit < Rake::TaskLib
    include Rake::Funnel::Support

    attr_accessor :name, :nunit, :files, :args

    def initialize(*args, &task_block)
      setup_ivars(args)

      define(args, &task_block)
    end

    private
    def setup_ivars(args)
      @name = args.shift || :test

      @nunit = 'nunit-console.exe'
      @args = {}
      @files = %w(build/specs/**/*.dll build/specs/**/*.exe)
    end

    def define(args, &task_block)
      desc "Test #{test_assemblies.all_or_default.join(', ')}" unless Rake.application.last_description

      task(name, *args) do |_, task_args|
        task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block

        Rake::Funnel::Integration::TeamCity::NUnitPlugin.setup(nunit)

        cmd = [
          *Mono.invocation(nunit),
          *test_assemblies.all,
          *Mapper.new(:NUnit).map(@args)
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
