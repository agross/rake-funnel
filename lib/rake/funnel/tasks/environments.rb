require 'configatron'
require 'rake/tasklib'

module Rake::Funnel::Tasks
  class Environments < Rake::TaskLib
    include Rake::Funnel::Support::Environments

    attr_accessor :base_dir, :store, :default_env, :default_config, :local_config, :customizer

    def initialize(*args, &task_block)
      setup_ivars(args)

      define(args, &task_block)
    end

    private
    def setup_ivars(_args)
      @store = configatron
      @default_env = nil
      @default_config = 'default'
      @local_config = 'local'
      @base_dir = 'config'
    end

    def define(args, &task_block)
      task_block.call(*[self].slice(0, task_block.arity)) if task_block

      environments.each do |env|
        desc "Configure for the #{env[:name]} environment"

        task(env[:name], *args) do |_, task_args|
          Loader.load_configuration(env, store, customizer)
        end
      end

      default_environment_setup
    end

    def environments
      default = File.join(base_dir, config_ext(default_config))
      local = File.join(base_dir, config_ext(local_config))

      Dir[File.join(base_dir, config_ext('*'))]
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
      return unless default_env

      top_level_envs = top_level_env_tasks
      if top_level_envs.empty?
        task = Rake.application.current_scope.path_with_task_name(default_env)
        prepend_task(task)
      else
        top_level_envs.each do |task|
          Rake.application.top_level_tasks.delete(task)
          prepend_task(task)
        end
      end
    end

    def prepend_task(task)
      Rake.application.top_level_tasks.unshift(task)
    end

    def top_level_env_tasks
      expect_user_defined = environments.map { |env| Rake.application.current_scope.path_with_task_name(env[:name]) }
      Rake.application.top_level_tasks.select { |t| expect_user_defined.include?(t) }
    end
  end
end
