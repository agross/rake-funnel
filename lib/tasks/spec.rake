# frozen_string_literal: true

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--order random'
  t.rspec_opts += ' --format progress --format html --out build/spec/rspec.html' if Integration::TeamCity.running?
end
