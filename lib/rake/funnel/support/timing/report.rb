require 'smart_colored/extend'

module Rake
  module Funnel
    module Support
      module Timing
        class Report
          class Column
            attr_reader :header

            def initialize(stats: [], header: '', accessor: ->(_) { '' })
              @stats = stats
              @header = header
              @accessor = accessor
            end

            def width
              longest_value = @stats.map { |s| @accessor.call(s) }.max_by(&:length) || ''
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

          def initialize(stats, opts = {})
            @stats = stats
            @opts = opts
          end

          def render
            header
            rows
            footer
          end

          def columns
            @columns ||= begin [
              Column.new(stats: @stats, header: 'Target', accessor: ->(timing) { timing[:task].name }),
              Column.new(stats: @stats, header: 'Duration', accessor: ->(timing) { format(timing[:time]) })
            ] end
          end

          private

          def header # rubocop:disable Metrics/AbcSize
            puts '-' * HEADER_WIDTH
            puts 'Build time report'
            puts '-' * HEADER_WIDTH

            puts columns.map(&:format_header).join(' ' * SPACE)
            puts columns.map { |c| c.format_header.gsub(/./, '-') }.join(' ' * SPACE)
          end

          def rows
            @stats.each do |timing|
              puts columns.map { |c| c.format_value(timing) }.join(' ' * SPACE)
            end
          end

          def footer # rubocop:disable Metrics/AbcSize
            puts '-' * HEADER_WIDTH
            puts 'Total'.ljust(columns[0].width) + ' ' * SPACE + format(Time.now - @stats.started_at)
            status_message
            puts '-' * HEADER_WIDTH
          end

          def format(seconds)
            Time.at(seconds).utc.strftime('%H:%M:%S')
          end

          def status_message # rubocop:disable Metrics/AbcSize
            status = @opts[:failed] ? 'Failed' : 'OK'
            status = 'Status'.ljust(columns[0].width) + ' ' * SPACE + status

            if @opts[:failed]
              $stderr.puts status.bold.red
            else
              $stdout.puts status.bold.green
            end
          end
        end
      end
    end
  end
end
