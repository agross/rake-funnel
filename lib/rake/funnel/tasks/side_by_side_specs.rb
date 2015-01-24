require 'rake/tasklib'

Dir["#{File.dirname(__FILE__)}/side_by_side_specs_support/*.rb"].each do |path|
  require path
end

module Rake::Funnel::Tasks
  class SideBySideSpecs < Rake::TaskLib
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
        SideBySideSpecsSupport::Remover.remove({ projects: projects, references: references, specs: specs })
      end

      self
    end
  end
end
