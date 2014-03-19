require 'rubygems'
require 'rubygems/package_task'

spec = Gem::Specification.load('pipeline.gemspec')

Gem::PackageTask.new(spec) do |t|
  t.package_dir = 'deploy'

  task :gem do
    rm_rf t.package_dir_path
  end
end
