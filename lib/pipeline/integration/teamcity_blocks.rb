require 'rake'

module Pipeline::Integration
  module TeamCityBlocks
    @rake_executes = []

    def self.included(mod)
      patch_rake_task(self)
    end

    def self.reset!
      reset_rake_task(self)
    end

    private
    def self.reset_rake_task(caller)
      return unless caller.patched?

      ::Rake.module_eval do
        Rake::Task.class_eval do
          old_execute = caller.pop

          define_method(:execute) do |args|
            old_execute.bind(self).call(args)
          end
        end
      end
    end

    def self.patch_rake_task(caller)
      return if caller.patched?

      ::Rake.module_eval do
        Rake::Task.class_eval do
          old_execute = caller.push(instance_method(:execute))

          define_method(:execute) do |args|
            TeamCity.block_opened({ name: name })

            begin
              old_execute.bind(self).call(args)
            ensure
              TeamCity.block_closed({ name: name })
            end
          end
        end
      end
    end

    def self.push(rake_execute)
      @rake_executes.push(rake_execute)
      rake_execute
    end

    def self.pop
      @rake_executes.pop
    end

    def self.patched?
      @rake_executes.any?
    end
  end
end
