require 'rake'
require 'rake/tasklib'

Dir["#{File.dirname(__FILE__)}/timing_support/*.rb"].each do |path|
  require path
end

module Rake::Funnel::Tasks
  class Timing < Rake::TaskLib
    attr_accessor :name
    attr_reader :stats

    def initialize(name = :timing)
      @name = name
      @stats = TimingSupport::Statistics.new

      yield self if block_given?

      define
    end

    def reset!
      patches.each { |p| p.revert! }
    end

    private
    def define
      patches.each { |p| p.apply! }

      task @name, :failed do |task, args|
        TimingSupport::Report.new(@stats, args).render
      end

      Rake.application.top_level_tasks.push(@name)

      self
    end

    def patches
      @patches ||= create_patches
    end

    def create_patches
      report = Rake::Funnel::Support::Patch.new do |p|
        report_invoker = -> (opts) { TimingSupport::Report.new(@stats, opts).render }

        p.setup do
          Rake::Application.class_eval do
            orig_display_error_message = instance_method(:display_error_message)

            define_method(:display_error_message) do |ex|
              orig_display_error_message.bind(self).call(ex)

              report_invoker.call(failed: true)
            end

            orig_display_error_message
          end
        end

        p.reset do |memo|
          Rake::Application.class_eval do
            define_method(:display_error_message) do |ex|
              memo.bind(self).call(ex)
            end
          end
        end
      end

      benchmark = Rake::Funnel::Support::Patch.new do |p|
        benchmark_invoker = -> (task, &block) { @stats.benchmark(task, &block) }

        p.setup do
          Rake::Task.class_eval do
            orig_execute = instance_method(:execute)

            define_method(:execute) do |args|
              benchmark_invoker.call(self) do
                orig_execute.bind(self).call(args)
              end
            end

            orig_execute
          end
        end

        p.reset do |memo|
          Rake::Task.class_eval do
            define_method(:execute) do |ex|
              memo.bind(self).call(ex)
            end
          end
        end
      end

      [report, benchmark]
    end
  end
end
