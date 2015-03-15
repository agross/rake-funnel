Tasks::MSDeploy.new(push: [:bin_path, :gem]) do |t|
  remote_path = configatron.deployment.remote_path.to_windows_path

  spec = Gem::Specification.load('rake-funnel.gemspec')

  gem = Gem::PackageTask.new(spec) do |task|
    task.package_dir = 'deploy'
  end

  gem = File.join(File.expand_path(gem.package_dir), gem.gem_spec.file_name)

  t.log_file = 'deploy/msdeploy.log'
  t.args = {
    verb: :sync,
    pre_sync: {
      run_command: "mkdir #{remote_path}\\gems",
      wait_interval: 60 * 1000
    },
    source: {
      file_path: gem
    },
    dest: {
      computer_name: configatron.deployment.connection.computer_name,
      username: configatron.deployment.connection.username,
      password: configatron.deployment.connection.password,
      file_path: File.join(remote_path, 'gems', File.basename(gem)).to_windows_path
    },
    skip: [{ skip_action: :delete }],
    post_sync_on_success: {
      run_command: "gem generate_index -V --directory=#{remote_path} & icacls #{remote_path} /reset /t /c /q",
      wait_interval: 60 * 1000
    },
    use_check_sum: nil,
    allow_untrusted: nil
  }
end
