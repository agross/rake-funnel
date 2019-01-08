# frozen_string_literal: true

require 'rubygems/package_task'

spec = Gem::Specification.load('rake-funnel.gemspec')

task gem: :spec do
  Integration::TeamCity::ServiceMessages.build_number(spec.version.to_s)
end

Gem::PackageTask.new(spec) do |t|
  t.package_dir = 'deploy'

  task :gem do
    rm_rf t.package_dir_path
  end
end
