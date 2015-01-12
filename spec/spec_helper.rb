require 'simplecov'
require 'coveralls'
require 'codeclimate-test-reporter'

SimpleCov.start do
  if Coveralls.will_run?
    external_services = [
      Coveralls::SimpleCov::Formatter,
      CodeClimate::TestReporter::Formatter
    ]
  end

  formatter SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      *external_services
    ]

  coverage_dir('build/coverage')
end

require 'rspec/its'
require 'rspec/collection_matchers'
require 'rake/funnel'

# When invoked via the rspec rake task, output needs to by synced.
Rake::Funnel::Integration::SyncOutput.new

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
