# frozen_string_literal: true

require 'rake'
require 'open3'
require 'smart_colored/extend'
require 'stringio'

module Rake
  module Funnel
    module Extensions
      module Shell
        def shell(*cmd, log_file: nil, error_lines: nil, &block)
          mkdir_p(File.dirname(log_file)) if log_file

          run(cmd, log_file, error_lines) do |success, readable_cmd, result, log|
            if block
              yield(success, readable_cmd, result, log)
              return
            end
          end
        end

        private

        def run(cmd, log_file, error_lines) # rubocop:disable Metrics/AbcSize
          cmd, readable_cmd = normalize(cmd)

          $stderr.print(readable_cmd + "\n")

          Open3.popen2e(*cmd) do |_, stdout_and_stderr, wait_thread|
            log, error_logged = log_output(stdout_and_stderr, log_file, error_lines)
            success = wait_thread.value.success? && error_logged == false

            result = [readable_cmd, wait_thread.value.exitstatus, log]

            yield(success, *result) if block_given?

            raise Rake::Funnel::ExecutionError.new(*result) unless success
          end
        end

        def normalize(cmd)
          cmd = cmd.flatten.reject(&:nil?)
          readable_cmd = cmd.join(' ')

          [cmd, readable_cmd]
        end

        def log_output(stdout_and_stderr, log_file, error_lines)
          log_string = StringIO.new

          begin
            statuses = log_lines(stdout_and_stderr, log_file, error_lines, log_string)

            [log_string.string, statuses.any? { |s| s == :error }]
          ensure
            log_string.close
          end
        end

        def log_lines(stdout_and_stderr, log_file, error_lines, log_string)
          stdout_and_stderr.map do |line|
            log_string.write(line)
            File.open(log_file, 'a') { |f| f.write(line) } if log_file

            handle_line(line, error_lines)
          end
        end

        def handle_line(line, error_lines)
          to_stderr(line, error_lines) || to_stdout(line)
        end

        def to_stdout(line)
          $stdout.print(line.rstrip.green + "\n")
          :success
        end

        def to_stderr(line, error_lines)
          return unless error_lines && line =~ error_lines

          $stderr.print(line.rstrip.bold.red + "\n")
          :error
        end
      end
    end
  end
end

module Rake
  module DSL
    include Rake::Funnel::Extensions::Shell
    private(*Rake::Funnel::Extensions::Shell.instance_methods(false))
  end
end
