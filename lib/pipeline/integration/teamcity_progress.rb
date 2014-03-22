require 'rake'

module Pipeline::Integration
  module TeamCityProgress
    def self.included(mod)
      patch.apply!
    end

    def self.reset!
      patch.revert!
    end

    private
    def self.patch
      @patch ||= create_patch
    end

    def self.create_patch
      Pipeline::Support::Patch.new do |p|
        p.setup do
          Rake::Task.class_eval do
            old_execute = instance_method(:execute)

            define_method(:execute) do |args|
              TeamCity.progress_start(name)

              begin
                old_execute.bind(self).call(args)
              ensure
                TeamCity.progress_finish(name)
              end
            end

            old_execute
          end
        end

        p.reset do |memo|
          Rake::Task.class_eval do
            define_method(:execute) do |args|
              memo.bind(self).call(args)
            end
          end
        end
      end
    end
  end
end
