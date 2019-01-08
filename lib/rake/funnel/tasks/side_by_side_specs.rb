# frozen_string_literal: true

require 'rake/tasklib'

module Rake
  module Funnel
    module Tasks
      class SideBySideSpecs < Rake::TaskLib
        include Rake::Funnel::Support

        attr_accessor :name, :projects, :references, :specs, :packages, :enabled

        def initialize(*args, &task_block)
          setup_ivars(args)

          define(args, &task_block)
        end

        private

        def setup_ivars(args)
          @name = args.shift || :compile

          @projects = %w(**/*.csproj **/*.vbproj **/*.fsproj)
          @references = []
          @specs = %w(*Specs.cs *Tests.cs)
          @enabled = false
          @packages = []
        end

        def define(args, &task_block)
          desc 'Remove tests from projects' unless Rake.application.last_description
          task(name, *args) do |_, task_args|
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block

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
            packages: packages
          }
        end
      end
    end
  end
end
