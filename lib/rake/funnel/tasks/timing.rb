require 'rake/tasklib'

module Rake
  module Funnel
    module Tasks
      class Timing < Rake::TaskLib
        include Rake::Funnel::Support::Timing

        attr_accessor :name
        attr_reader :stats

        def initialize(*args, &task_block)
          setup_ivars(args)

          define(args, &task_block)
        end

        def reset!
          patches.each(&:revert!)
        end

        private

        def setup_ivars(args)
          @name = args.shift || :timing

          @stats = Statistics.new
        end

        def define(_args, &task_block)
          patches.each(&:apply!)

          task name, :failed do |_, task_args|
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block

            Report.new(@stats, task_args).render
          end

          timing_task = Rake.application.current_scope.path_with_task_name(@name)
          Rake.application.top_level_tasks.push(timing_task)

          self
        end

        def patches
          @patches ||= [report, benchmark]
        end

        def report # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          Rake::Funnel::Support::Patch.new do |p|
            report_invoker = ->(opts) { Report.new(@stats, opts).render }

            p.setup do
              Rake::Application.class_eval do
                orig_display_error_message = instance_method(:display_error_message)

                define_method(:display_error_message) do |*args|
                  orig_display_error_message.bind(self).call(*args)

                  report_invoker.call(failed: true)
                end

                orig_display_error_message
              end
            end

            p.reset do |memo|
              Rake::Application.class_eval do
                define_method(:display_error_message) do |*args|
                  memo.bind(self).call(*args)
                end
              end
            end
          end
        end

        def benchmark # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          Rake::Funnel::Support::Patch.new do |p|
            benchmark_invoker = ->(task, &block) { @stats.benchmark(task, &block) }

            p.setup do
              Rake::Task.class_eval do
                orig_execute = instance_method(:execute)

                define_method(:execute) do |*args|
                  benchmark_invoker.call(self) do
                    orig_execute.bind(self).call(*args)
                  end
                end

                orig_execute
              end
            end

            p.reset do |memo|
              Rake::Task.class_eval do
                define_method(:execute) do |*args|
                  memo.bind(self).call(*args)
                end
              end
            end
          end
        end
      end
    end
  end
end
