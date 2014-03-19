require 'rubygems/package_task'
require 'rspec/core/rake_task'

task default: :spec

RSpec::Core::RakeTask.new(:spec)

spec = Gem::Specification.load('pipeline.gemspec')
Gem::PackageTask.new(spec) do |t|
  t.package_dir = 'deploy'

  task :gem => :spec do
    rm_rf t.package_dir_path
  end
end
