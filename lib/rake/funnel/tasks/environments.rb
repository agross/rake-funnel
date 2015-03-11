require 'rake/tasklib'

Dir["#{File.dirname(__FILE__)}/environments_support/*.rb"].each do |path|
  require path
end

module Rake::Funnel::Tasks
  class Environments < Rake::TaskLib
    include Rake::Funnel::Support::Environments

    attr_accessor :base_dir, :default_env, :default_config, :local_config, :customizer

    def initialize
      @default_env = nil
      @default_config = 'default'
      @local_config = 'local'
      @base_dir = 'config'

      yield self if block_given?
      define
      default_environment_setup

      self
    end

    private
    def define
      environments.each do |env|
        desc "Configure for the #{env[:name]} environment"
        task env[:name] do
          Loader.load_configuration(env, configatron, customizer)
        end
      end
    end

    def environments
      default = File.join(@base_dir, config_ext(default_config))
      local = File.join(@base_dir, config_ext(local_config))

      Dir[File.join(@base_dir, config_ext('*'))]
        .reject { |config| config == default || config == local }
        .map do |config|
        {
          name: File.basename(config, '.*'),
          config_files: [
            File.exists?(default) ? default : nil,
            config,
            File.exists?(local) ? local : nil
          ].compact
        }
      end
    end

    def config_ext(name)
      "#{name}.yaml"
    end

    def default_environment_setup
      return unless @default_env

      tasks = user_defined_env_tasks
      if tasks.empty?
        tasks = [] << Rake.application.current_scope.path_with_task_name(@default_env)
      end

      tasks.each do |task|
        Rake::Task[task].invoke
      end
    end

    def user_defined_env_tasks
      expect_user_defined = environments.map { |env| Rake.application.current_scope.path_with_task_name(env[:name]) }
      Rake.application.top_level_tasks.select { |t| expect_user_defined.include?(t) }
    end
  end
end
