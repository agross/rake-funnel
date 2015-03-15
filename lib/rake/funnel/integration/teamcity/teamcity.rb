module Rake::Funnel::Integration
  module TeamCity
    ENV_VAR = 'TEAMCITY_PROJECT_NAME'

    class << self
      def running?
        ENV.include?(ENV_VAR)
      end

      def rake_runner?
        running? && Object.const_defined?('Rake') && Rake.const_defined?('TeamCityApplication')
      end
    end
  end
end
