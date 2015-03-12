Tasks::MSDeploy.new :push => [:bin_path, :gem] do |t|
  spec = Gem::Specification.load('rake-funnel.gemspec')

  gem = Gem::PackageTask.new(spec)
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
      computer_name: configatron.deployment.connection.computer_name,
      username: configatron.deployment.connection.username,
      password: configatron.deployment.connection.password,
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
