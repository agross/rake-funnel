require 'rake/tasklib'

module Rake
  module Funnel
    module Tasks
      class SideBySideSpecs < Rake::TaskLib
        include Rake::Funnel::Support

        attr_accessor :name, :projects, :references, :specs, :enabled
        attr_accessor :paket_references, :packages

        def initialize(*args, &task_block)
          setup_ivars(args)

          define(args, &task_block)
        end

        private
        def setup_ivars(args)
          @name = args.shift || :compile

          @projects = %w(**/*.csproj **/*.vbproj **/*.fsproj)
          @references = []
          @specs = %w(*Specs.cs **/*Specs.cs *Tests.cs **/*Tests.cs)
          @enabled = false
          @paket_references = %w(**/*paket.references)
          @packages = []
        end

        def define(args, &task_block)
          desc 'Remove tests from projects' unless Rake.application.last_description
          task(name, *args) do |_, task_args|
            task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block

            next unless enabled

            SpecsRemover.remove(remove_args)
          end

          self
        end

        def remove_args
          {
            projects: projects,
            references: references,
            specs: specs,
            paket_references: paket_references,
            packages: packages
          }
        end
      end
    end
  end
end
