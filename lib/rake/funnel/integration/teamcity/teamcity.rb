module Rake
  module Funnel
    module Integration
      module TeamCity
        PROJECT_ENV_VAR = 'TEAMCITY_PROJECT_NAME'
        JRE_ENV_VAR = 'TEAMCITY_JRE'

        class << self
          def running?
            ENV.include?(PROJECT_ENV_VAR)
          end

          def rake_runner?
            running? && Object.const_defined?('Rake') && Rake.const_defined?('TeamCityApplication')
          end

          def with_java_runtime(&block)
            return unless block_given?

            begin
              original_path = ENV['PATH']

              ENV['PATH'] = ([] << ENV['PATH'] << teamcity_jre).compact.join(File::PATH_SEPARATOR)

              block.call
            ensure
              ENV['PATH'] = original_path
            end
          end

          private
          def teamcity_jre
            return nil unless ENV.include?(JRE_ENV_VAR)
            File.join(ENV[JRE_ENV_VAR], 'bin')
          end
        end
      end
    end
  end
end
