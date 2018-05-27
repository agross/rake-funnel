require 'rake'

module Rake
  module Funnel
    module Integration
      class ProgressReport
        attr_reader :starting, :finished

        def initialize
          task_starting do |task, _args|
            puts "\n[#{task.name}]".bold.cyan unless Rake::Funnel::Integration::TeamCity.running?
          end

          yield self if block_given?

          patch.apply!
        end

        def task_starting(&block)
          @starting = block
        end

        def task_finished(&block)
          @finished = block
        end

        def disable!
          patch.revert!
        end

        private

        def patch
          @patch ||= create_patch
        end

        def create_patch # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          Rake::Funnel::Support::Patch.new(self) do |p|
            p.setup do |context|
              Rake::Task.class_eval do
                old_execute = instance_method(:execute)

                define_method(:execute) do |*args|
                  context.starting.call(self, *args) if context.starting

                  error = nil
                  begin
                    old_execute.bind(self).call(*args)
                  rescue => e # rubocop:disable Style/RescueStandardError
                    error = e
                  ensure
                    context.finished.call(self, *args, error) if context.finished
                    raise error if error
                  end
                end

                old_execute
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
