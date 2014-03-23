require 'rake'

module Pipeline::Integration
  class ProgressReport
    attr_accessor :starting, :finished

    def initialize
      task_starting do |task, args|
        TeamCity.block_opened({ name: task.name })
        TeamCity.progress_start(task.name)
        puts "\n[#{task.name}]" unless TeamCity.running?
      end

      task_finished do |task, args, error|
        TeamCity.build_problem({ description: error.message[0..4000 - 1] }) if error
        TeamCity.progress_finish(task.name)
        TeamCity.block_closed({ name: task.name })
      end

      yield self if block_given?

      patch.apply!
    end

    def reset!
      patch.revert!
    end

    def task_starting(&block)
      @starting = block
    end

    def task_finished(&block)
      @finished = block
    end

    private
    def patch
      @patch ||= create_patch
    end

    def create_patch
      Pipeline::Support::Patch.new(self) do |p|
        p.setup do |context|
          Rake::Task.class_eval do
            old_execute = instance_method(:execute)

            define_method(:execute) do |args|
              context.starting.call(self, args)

              error = nil
              begin
                old_execute.bind(self).call(args)
              rescue => e
                error = e
              ensure
                context.finished.call(self, args, error)
                raise error if error
              end
            end

            old_execute
          end
        end

        p.reset do |memo|
          Rake::Task.class_eval do
            define_method(:execute) do |args|
              memo.bind(self).call(args)
            end
          end
        end
      end
    end
  end
end
