require 'rake'
require 'rake/tasklib'
require 'smart_colored/extend'

module Pipeline::Tasks
  class Timing < Rake::TaskLib
    class Statistics
      include Enumerable

      attr_reader :started_at

      def initialize
        @stats = []
        @started_at = Time.now
      end

      def each(&block)
        @stats.each(&block)
      end

      def benchmark(task)
        t0 = Time.now
        begin
          yield if block_given?
        ensure
          t1 = Time.now
          @stats << { task: task, time: t1 - t0 }
        end
      end
    end

    class Report
      class Column
        attr_reader :header

        def initialize(stats: [], header: '', accessor: -> (_) { '' })
          @stats = stats
          @header = header
          @accessor = accessor
        end

        def width
          longest_value = @stats.map { |s| @accessor.call(s) }.max_by { |m| m.length } || ''
          width = longest_value.length
          width = @header.length if width < @header.length
          width
        end

        def format_header
          @header.ljust(width)
        end

        def format_value(value)
          @accessor.call(value).ljust(width)
        end
      end

      SPACE = 3
      HEADER_WIDTH = 70

      def initialize(stats , opts = {})
        @stats = stats
        @opts = opts
      end

      def render
        puts "\n\n" + '-' * HEADER_WIDTH
        puts 'Build time report'
        puts '-' * HEADER_WIDTH

        puts columns.map { |c| c.format_header }.join(' ' * SPACE)
        puts columns.map { |c| c.format_header.gsub(/./, '-') }.join(' ' * SPACE)

        @stats.each do |timing|
          puts columns.map { |c| c.format_value(timing) }.join(' ' * SPACE)
        end

        puts '-' * HEADER_WIDTH
        puts 'Total'.ljust(columns[0].width) + ' ' * SPACE + format(Time.now - @stats.started_at)
        puts status_message
        puts '-' * HEADER_WIDTH
      end

      def columns
        @columns ||= (
          [
            Column.new(stats: @stats, header: 'Target',   accessor: -> (timing) { timing[:task].name }),
            Column.new(stats: @stats, header: 'Duration', accessor: -> (timing) { format(timing[:time]) })
          ]
        )
      end

      private
      def format(seconds)
        Time.at(seconds).utc.strftime('%H:%M:%S')
      end

      def status_message
        status = @opts[:failed] ? 'Failed' : 'OK'
        status = 'Status'.ljust(columns[0].width) + ' ' * SPACE + status

        return status.bold.red if @opts[:failed]
        status.bold.green
      end
    end

    attr_accessor :name
    attr_reader :stats

    def initialize(name = :timing)
      @name = name
      @stats = Statistics.new

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
        Report.new(@stats, args).render
      end

      Rake.application.top_level_tasks.push(@name)

      self
    end
  end
end
