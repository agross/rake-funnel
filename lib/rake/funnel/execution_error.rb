module Rake
  module Funnel
    class ExecutionError < StandardError
      attr_reader :command, :exit_code, :output, :description

      def initialize(command = nil, exit_code = nil, output = nil, description = nil)
        super(description)

        @description = description
        @command = command
        @exit_code = exit_code
        @output = output
      end

      def to_s
        msg = [] << inspect_description << inspect_command << inspect_exit_code << last_output
        msg = msg.flatten.compact
        msg = [super.to_s] if msg.empty?

        msg.join("\n")
      end

      private
      def inspect_description
        [description] if description
      end

      def inspect_command
        ['Error executing:', command] if command
      end

      def inspect_exit_code
        ["Exit code: #{exit_code}"] if exit_code
      end

      def last_output
        ['Command output (last 10 lines):', output.encode('UTF-8').split("\n").last(10)] if output
      end
    end
  end
end
