module Pipeline
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
      msg = []
      (msg << description << nil) if description
      (msg << 'Error executing:' << command << nil) if command
      (msg << "Exit code: #{exit_code}" << nil) if exit_code
      (msg << 'Command output (last 10 lines):' << output.split("\n").last(10)) if output

      msg = [super.to_s] if msg.empty?

      msg.join("\n")
    end
  end
end
