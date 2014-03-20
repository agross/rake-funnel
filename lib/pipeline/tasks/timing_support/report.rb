require 'smart_colored/extend'

module Pipeline::Tasks::TimingSupport
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
end
