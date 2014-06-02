require 'rake/funnel'
require 'rubygems/package_task'
require 'rspec/core/rake_task'

Rake::Funnel::Tasks::Timing.new
Rake::Funnel::Tasks::BinPath.new
Rake::Funnel::Integration::SyncOutput.new
Rake::Funnel::Integration::ProgressReport.new

task default: :spec

RSpec::Core::RakeTask.new(:spec)

spec = Gem::Specification.load('rake-funnel.gemspec')
gem = Gem::PackageTask.new(spec) do |t|
  t.package_dir = 'deploy'

  task :gem do
    rm_rf t.package_dir_path
  end
end

task gem: :spec do
  Rake::Funnel::Integration::TeamCity.build_number(spec.version.to_s)
end

desc 'Publish the gem file ' + File.basename(gem.gem_spec.cache_file)
Rake::Funnel::Tasks::MSDeploy.new :push => [:bin_path, :gem] do |t|
  t.log_file = 'deploy/msdeploy.log'
  t.args = {
    verb: :sync,
    post_sync: {
      run_command: 'gem generate_index -V --directory=C:/GROSSWEBER/gems & icacls C:/GROSSWEBER/gems /reset /t /c /q',
      :wait_interval => 60 * 1000
    },
    source: {
      content_path: File.expand_path('deploy')
    },
    dest: {
      computer_name: 'gems.grossweber.com',
      username: ENV['DEPLOY_USER'],
      password: ENV['DEPLOY_PASSWORD'],
      content_path: 'C:/GROSSWEBER/gems/gems'
    },
    skip: [{ skipAction: :delete }],
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
