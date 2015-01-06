module Rake::Funnel::Integration
  module TeamCity
    class << self
      def running?
        ENV.include?('TEAMCITY_PROJECT_NAME')
      end

      def rake_runner?
        running? && Object.const_defined?('Rake') && Rake.const_defined?('TeamCityApplication')
      end
    end
  end
end
