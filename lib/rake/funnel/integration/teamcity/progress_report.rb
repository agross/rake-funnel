require 'rake'

module Rake
  module Funnel
    module Integration
      module TeamCity
        class ProgressReport < Rake::Funnel::Integration::ProgressReport
          include Rake::Funnel::Integration

          def initialize # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
            super do
              task_starting do |task, _args|
                next unless TeamCity.running?

                unless TeamCity.rake_runner?
                  ServiceMessages.block_opened(name: task.name)
                end
              end

              task_finished do |task, _args, error|
                next unless TeamCity.running?

                if error.respond_to?(:inner_exception)
                  error = error.inner_exception
                end

                ServiceMessages.build_problem(description: error.message[0..4000 - 1]) if error

                next if Rake::Funnel::Integration::TeamCity.rake_runner?

                ServiceMessages.block_closed(name: task.name)
              end
            end
          end
        end
      end
    end
  end
end
