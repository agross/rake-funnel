require 'rake/tasklib'

module Rake::Funnel::Tasks
  class Paket < Rake::TaskLib
    include Rake::Funnel::Support

    attr_accessor :name, :paket, :paket_args, :bootstrapper, :bootstrapper_args

    def initialize(*args, &task_block)
      setup_ivars(args)

      define(args, &task_block)
    end

    private
    def setup_ivars(args)
      @name = args.shift || :paket

      @paket = File.join('.paket', 'paket.exe')
      @paket_args = 'restore'

      @bootstrapper = File.join('.paket', 'paket.bootstrapper.exe')
      @bootstrapper_args = nil
    end

    def define(args, &task_block)
      desc 'Restore packages' unless Rake.application.last_description

      task(name, *args) do |_, task_args|
        task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block

        sh(*bootstrapper_cmd) unless File.exist?(paket)
        sh(*paket_cmd)
      end

      self
    end

    def bootstrapper_cmd
      Mono.invocation(bootstrapper, bootstrapper_args)
    end

    def paket_cmd
      Mono.invocation(paket, paket_args)
    end
  end
end
