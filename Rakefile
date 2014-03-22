require 'rake'
require 'pipeline'
require 'rubygems/package_task'
require 'rspec/core/rake_task'

task default: :spec

RSpec::Core::RakeTask.new(:spec)

spec = Gem::Specification.load('pipeline.gemspec')
gem = Gem::PackageTask.new(spec) do |t|
  t.package_dir = 'deploy'

  task gem: :spec do
    rm_rf t.package_dir_path
  end
end

Pipeline::Tasks::Timing.new
Pipeline::Tasks::BinPath.new
Pipeline::Integration::ProgressReport.new

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
