require 'rspec/its'
require 'rspec/collection_matchers'
require 'simplecov'
require 'coveralls'
require 'codeclimate-test-reporter'
require 'bundler/setup'
require 'simplecov-teamcity-summary'

SimpleCov.start do
  if Coveralls.will_run?
    external_services = [
      Coveralls::SimpleCov::Formatter,
      CodeClimate::TestReporter::Formatter
    ]
  end

  formatter SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      *external_services
    ]
  )

  coverage_dir('build/coverage')

  at_exit do
    result = SimpleCov.result
    result.format!

    next unless Rake::Funnel::Integration::TeamCity.running?

    SimpleCov::Formatter::TeamcitySummaryFormatter.new.format(result)
    Rake::Funnel::Integration::TeamCity::ServiceMessages.build_status(text: "{build.status.text}, Code Coverage #{result.covered_percent.round(2)}%")
  end
end

# Require below SimpleCov.start to get coverage for files in lib.
require 'rake/funnel'

# When invoked via the rspec rake task, output needs to by synced.
Rake::Funnel::Integration::SyncOutput.new

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
