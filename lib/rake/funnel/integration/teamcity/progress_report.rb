require 'rake'

module Rake::Funnel::Integration::TeamCity
  class ProgressReport < Rake::Funnel::Integration::ProgressReport
    include Rake::Funnel::Integration

    def initialize
      super do
        task_starting do |task, args|
          next unless TeamCity.running?

          unless TeamCity.rake_runner?
            ServiceMessages.block_opened({ name: task.name })
            ServiceMessages.progress_start(task.name)
          end
        end

        task_finished do |task, args, error|
          next unless TeamCity.running?

          if error.respond_to?(:inner_exception)
            error = error.inner_exception
          end

          ServiceMessages.build_problem({ description: error.message[0..4000 - 1] }) if error

          next if Rake::Funnel::Integration::TeamCity.rake_runner?

          ServiceMessages.progress_finish(task.name)
          ServiceMessages.block_closed({ name: task.name })
        end
      end
    end
  end
end
