require 'rake'
require 'open3'
require 'smart_colored/extend'

module Rake::Funnel::Extensions
  module Shell
    def shell(*cmd, log_file: nil, error_lines: nil)
      mkdir_p(File.dirname(log_file)) if log_file

      stdout = -> (msg) { $stdout.puts msg.sub(/\n$/, '').green }

      error_logged = false
      stderr = -> (msg) {
        error_logged = true
        $stderr.puts msg.sub(/\n$/, '').bold.red
      }

      log = StringIO.new

      begin
        cmd = cmd.flatten.reject(&:nil?)
        Rake.rake_output_message(cmd.join(' '))

        Open3.popen2e(*cmd) do |_, stdout_and_stderr, wait_thread|
          stdout_and_stderr.each do |line|
            out = stdout
            out = stderr if error_lines && line =~ error_lines
            out.call(line)

            log.write(line)
            File.open(log_file, 'a') { |f| f.write(line) } if log_file
          end

          success = wait_thread.value.success? && error_logged == false
          result = [cmd.join(' '),
            wait_thread.value.exitstatus,
            log.string]

          if block_given?
            yield(success, *result)
            return
          end

          raise Rake::Funnel::ExecutionError.new(*result) unless success
        end
      ensure
        log.close
      end
    end
  end
end

module Rake::DSL
  include Rake::Funnel::Extensions::Shell
  private(*Rake::Funnel::Extensions::Shell.instance_methods(false))
end
