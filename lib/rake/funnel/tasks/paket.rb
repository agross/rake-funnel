require 'rake/tasklib'

module Rake::Funnel::Tasks
  class Paket < Rake::TaskLib
    include Rake::Funnel::Support

    attr_accessor :name, :paket, :paket_args, :bootstrapper, :bootstrapper_args

    def initialize(name = :paket)
      @name = name

      @paket = File.join('.paket', 'paket.exe')
      @paket_args = 'restore'

      @bootstrapper = File.join('.paket', 'paket.bootstrapper.exe')
      @bootstrapper_args = nil

      yield self if block_given?
      define
    end

    private
    def define
      desc "#{paket_cmd.join(' ')} (optionally #{bootstrapper_cmd.join(' ')})"
      task name do
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
