require 'rake/clean'
require 'rake/tasklib'
require 'open3'
require 'smart_colored/extend'

module Pipeline::Tasks
  class MSDeploy < Rake::TaskLib
    attr_accessor :name, :msdeploy, :log_file, :args

    def initialize(name = :msdeploy)
      @name = name
      @msdeploy = 'msdeploy'
      @args = {}

      yield self if block_given?
      define
    end

    def log_file
      @log_file || "#{@name}.log"
    end

    def transform_args
      args = []

      @args.each do |key, value|
        key = camel_case(key)

        if value.kind_of?(Enumerable)
          value = value.map do |left, right|
            left = nil if right.kind_of?(FalseClass)
            right = needs_equal(camel_case(right))
            "#{camel_case(left)}#{right}"
          end.join(',')
        else
          value = camel_case(value)
        end

        args << "#{needs_dash(key, value)}#{needs_colon(value)}"
      end

      args
    end

    private
    def define
      CLEAN.include(log_file)

      task @name do
        mkdir_p(File.dirname(log_file))

        cmd = [@msdeploy, transform_args]

        run_with_redirected_output(cmd) do |ok, status_code, command, log|
          if ok
            puts "Deployment successful."
          else
            message = %Q(
Deployment errors occurred, exit code #{status_code}. Please review #{log_file}.

10 last logged lines:
#{log}

Tried to execute:
#{command}

)

            raise Pipeline::ExecutionError.new(message)
          end
        end
      end

      self
    end

    def run_with_redirected_output(cmd)
      cmd = cmd.flatten.map {|e| quote(e) }.join(' ')
      puts cmd

      all_messages = StringIO.new
      begin
        stdout = -> (msg) { $stdout.puts msg.gsub(/\n/, '').green }
        stderr = -> (msg) { $stderr.puts msg.gsub(/\n/, '').bold.red }

        log = -> (msg) {
          File.open(log_file, 'a') { |f| f.write(msg) }

          all_messages.puts(msg)

          stdout = stderr if msg =~ /error|exception/i
          stdout.call(msg)
        }

        Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thread|
          stdout_and_stderr.each do |line|
            log.call(line)
          end

          ret = [wait_thread.value.success? && stdout != stderr,
                 wait_thread.value.exitstatus,
                 cmd,
                 all_messages.string.split("\n").last(10).join("\n")]
          yield ret if block_given?

          return ret
        end
      ensure
        all_messages.close
      end
    end

    def needs_dash(key, value)
      "-#{key}" if value
    end

    def needs_colon(value)
      return nil if value.kind_of?(TrueClass)
      ":#{value}" if value && !value.to_s.empty?
    end

    def needs_equal(value)
      return nil if value.kind_of?(TrueClass)
      "=#{value}" if value
    end

    def camel_case(value)
      return quote(value) unless value.kind_of?(Symbol)
      value.camelize
    end

    def quote(value)
      return %Q{"#{value}"} if value =~ /\s/ && value !~ /"/
      value
    end
  end
end
