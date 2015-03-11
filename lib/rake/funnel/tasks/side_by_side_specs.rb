require 'rake/tasklib'

module Rake::Funnel::Tasks
  class SideBySideSpecs < Rake::TaskLib
    include Rake::Funnel::Support::SideBySideSpecs

    attr_accessor :name, :projects, :references, :specs, :enabled

    def initialize(name = :compile)
      @name = name

      @projects = %w(**/*.csproj **/*.vbproj **/*.fsproj)
      @references = []
      @specs = %w(*Specs.cs **/*Specs.cs *Tests.cs **/*Tests.cs)
      @enabled = false

      yield self if block_given?
      define
    end

    private
    def define
      task name do
        next unless enabled
        Remover.remove({ projects: projects, references: references, specs: specs })
      end

      self
    end
  end
end
