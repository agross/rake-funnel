# frozen_string_literal: true

require 'rake/tasklib'

module Rake
  module Funnel
    module Tasks
      class MSBuild < Rake::TaskLib
        include Rake::Funnel::Support
        include Rake::Funnel::Support::MSBuild

        attr_accessor :name, :msbuild, :msbuild_finder, :project_or_solution, :args, :search_pattern
        attr_writer :project_or_solution # rubocop:disable Lint/DuplicateMethods

        def initialize(*args, &task_block)
          setup_ivars(args)

          define(args, &task_block)
        end

        def project_or_solution # rubocop:disable Lint/DuplicateMethods
          Finder.new(@project_or_solution || search_pattern, self, 'No projects or more than one project found.')
        end

        private

        def setup_ivars(args)
          @name = args.shift || :compile

          @msbuild = nil
          @msbuild_finder = -> { BuildTool.find }
          @args = {}
          @search_pattern = %w(**/*.sln)
        end

        def define(args, &task_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          desc 'Compile MSBuild projects' unless Rake.application.last_description

          task(name, *args) do |_, task_args|
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block

            cmd = [
              msbuild || msbuild_finder.call,
              project_or_solution.single,
              *Mapper.new(:MSBuild).map(@args)
            ]

            sh(*cmd)
          end

          self
        end
      end
    end
  end
end
