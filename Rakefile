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

desc 'Publish the gem file ' + File.basename(gem.gem_spec.cache_file)
Pipeline::Tasks::MSDeploy.new :push => [:bin_path, :gem] do |t|
  t.log_file = 'tmp/msdeploy.log'
  t.args = {
    verb: :sync,
    source: {
      content_path: File.expand_path('deploy')
    },
    dest: {
      computer_name: 'somewhere',
      username: 'someone',
      password: 'secret',
      content_path: 'C:/GROSSWEBER/gems/gems'
    },
    usechecksum: true,
    allow_untrusted: true
  }
end
