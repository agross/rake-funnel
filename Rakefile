require 'rake/funnel'
require 'rubygems/package_task'
require 'rspec/core/rake_task'

include Rake::Funnel

Tasks::Timing.new
Tasks::BinPath.new
Integration::SyncOutput.new
Integration::ProgressReport.new
Integration::TeamCity::ProgressReport.new

namespace :env do
  Tasks::Environments.new do |t|
    t.default_env = :dev
  end
end

task default: :spec

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--order random'
  if Integration::TeamCity.running?
    t.rspec_opts += ' --format progress --format html --out build/spec/rspec.html'
  end
  t.rspec_opts += ' --tag ~platform:win32' unless Rake::Win32.windows?
end

spec = Gem::Specification.load('rake-funnel.gemspec')
gem = Gem::PackageTask.new(spec) do |t|
  t.package_dir = 'deploy'

  task :gem do
    rm_rf t.package_dir_path
  end
end

task gem: :spec do
  Integration::TeamCity::ServiceMessages.build_number(spec.version.to_s)
end

Tasks::MSDeploy.new :push => [:bin_path, :gem] do |t|
  gem = File.join(File.expand_path(gem.package_dir), gem.gem_spec.file_name)

  t.log_file = 'deploy/msdeploy.log'
  t.args = {
    verb: :sync,
    pre_sync: {
      run_command: "mkdir #{configatron.deployment.remote_dir}\\gems",
      wait_interval: 60 * 1000
    },
    source: {
      file_path: gem
    },
    dest: {
      computer_name: configatron.deployment.computer_name,
      username: configatron.deployment.username,
      password: configatron.deployment.password,
      file_path: File.join(configatron.deployment.remote_dir, 'gems', File.basename(gem))
    },
    skip: [{ skip_action: :delete }],
    post_sync_on_success: {
      run_command: "gem generate_index -V --directory=#{configatron.deployment.remote_dir} & icacls #{configatron.deployment.remote_dir} /reset /t /c /q",
      wait_interval: 60 * 1000
    },
    use_check_sum: nil,
    allow_untrusted: nil
  }
end

task :fail do
  raise 'this build is expected to fail'
end

task :long_running do
  sleep(30)
end
