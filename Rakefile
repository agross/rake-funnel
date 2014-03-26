require 'rake'
require 'pipeline'
require 'rubygems/package_task'
require 'rspec/core/rake_task'

Pipeline::Tasks::Timing.new
Pipeline::Tasks::BinPath.new
Pipeline::Integration::SyncOutput.new
Pipeline::Integration::ProgressReport.new

task default: :spec

RSpec::Core::RakeTask.new(:spec)

spec = Gem::Specification.load('pipeline.gemspec')
gem = Gem::PackageTask.new(spec) do |t|
  t.package_dir = 'deploy'

  task :gem do
    rm_rf t.package_dir_path
  end
end

task gem: :spec do
  Pipeline::Integration::TeamCity.build_number(spec.version.to_s)
end

desc 'Publish the gem file ' + File.basename(gem.gem_spec.cache_file)
Pipeline::Tasks::MSDeploy.new :push => [:bin_path, :gem] do |t|
  t.log_file = 'tmp/msdeploy.log'
  t.args = {
    verb: :sync,
    source: {
      content_path: File.expand_path('deploy')
    },
    dest: {
      computer_name: 'gems.grossweber.com',
      username: ENV['DEPLOY_USER'] || '',
      password: ENV['DEPLOY_PASSWORD'] || '',
      content_path: 'C:/GROSSWEBER/gems/gems'
    },
    skip: [{ skipAction: :delete }],
    usechecksum: true,
    allow_untrusted: true
  }
end

Pipeline::Tasks::MSDeploy.new :push => :bin_path do |t|
  cmd = 'gem generate_index -V --directory=C:/GROSSWEBER/gems & icacls C:/GROSSWEBER/gems /reset /t /c /q'

  t.log_file = 'tmp/msdeploy.log'
  t.args = {
    verb: :sync,
    source: {
      run_command: cmd,
      success_return_codes: 0,
      wait_interval: 60 * 1000
    },
    dest: {
      computer_name: 'gems.grossweber.com',
      username: ENV['DEPLOY_USER'] || '',
      password: ENV['DEPLOY_PASSWORD'] || '',
      auto: true
    },
    usechecksum: true,
    allow_untrusted: true
  }
end

task :fail do
  raise 'this build is expected to fail'
end

task :long_running do
  sleep(30)
end
