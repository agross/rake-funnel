require 'rake/funnel'
require 'rubygems/package_task'
require 'rspec/core/rake_task'

Rake::Funnel::Tasks::Timing.new
Rake::Funnel::Tasks::BinPath.new
Rake::Funnel::Integration::SyncOutput.new
Rake::Funnel::Integration::ProgressReport.new
Rake::Funnel::Integration::TeamCity::ProgressReport.new

task default: :spec

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--order random'
  if ENV.include?('TEAMCITY_PROJECT_NAME')
    t.rspec_opts += ' --format progress --format html --out build/spec/rspec.html'
  end
end

spec = Gem::Specification.load('rake-funnel.gemspec')
gem = Gem::PackageTask.new(spec) do |t|
  t.package_dir = 'deploy'

  task :gem do
    rm_rf t.package_dir_path
  end
end

task gem: :spec do
  Rake::Funnel::Integration::TeamCity::ServiceMessages.build_number(spec.version.to_s)
end

desc "Publish the gem file #{gem.gem_spec.file_name}"
Rake::Funnel::Tasks::MSDeploy.new :push => [:bin_path, :gem] do |t|
  remote_dir = 'C:/GROSSWEBER/gems'
  gem = File.join(File.expand_path(gem.package_dir), gem.gem_spec.file_name)

  t.log_file = 'deploy/msdeploy.log'
  t.args = {
    verb: :sync,
    post_sync: {
      run_command: "gem generate_index -V --directory=#{remote_dir} & icacls C:/GROSSWEBER/gems /reset /t /c /q",
      wait_interval: 60 * 1000
    },
    source: {
      file_path: gem
    },
    dest: {
      computer_name: 'gems.grossweber.com',
      username: ENV['DEPLOY_USER'],
      password: ENV['DEPLOY_PASSWORD'],
      file_path: File.join(remote_dir, 'gems', File.basename(gem))
    },
    skip: [{ skip_action: :delete }],
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
