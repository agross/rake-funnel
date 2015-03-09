require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--order random'
  if Integration::TeamCity.running?
    t.rspec_opts += ' --format progress --format html --out build/spec/rspec.html'
  end
  t.rspec_opts += ' --tag ~platform:win32' unless Rake::Win32.windows?
end