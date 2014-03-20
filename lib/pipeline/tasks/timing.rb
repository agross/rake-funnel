require 'rake'
require 'rake/tasklib'

Dir["#{File.dirname(__FILE__)}/timing_support/*.rb"].each do |path|
  require path
end

module Pipeline::Tasks
  class Timing < Rake::TaskLib
    attr_accessor :name
    attr_reader :stats

    def initialize(name = :timing)
      @name = name
      @stats = TimingSupport::Statistics.new

      yield self if block_given?
      define
    end

    private
    def monkey_patch_rake_application
      benchmark_invoker = -> (task, &block) { @stats.benchmark(task, &block) }
      report_invoker = -> (opts) { Report.new(@stats, opts).render }

      ::Rake.module_eval do
        Rake::Application.class_eval do
          orig_display_error_message = instance_method(:display_error_message)

          define_method(:display_error_message) do |ex|
            orig_display_error_message.bind(self).call(ex)

            report_invoker.call(failed: true)
          end
        end

        Rake::Task.class_eval do
          orig_execute = instance_method(:execute)

          define_method(:execute) do |args|
            benchmark_invoker.call(self) do
              orig_execute.bind(self).call(args)
            end
          end
        end
      end
    end

    def define
      monkey_patch_rake_application

      task @name, :failed do |task, args|
        TimingSupport::Report.new(@stats, args).render
      end

      Rake.application.top_level_tasks.push(@name)

      self
    end
  end
end
