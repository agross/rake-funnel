require 'rake/clean'
require 'rake/tasklib'
require 'open3'
require 'smart_colored/extend'

Dir["#{File.dirname(__FILE__)}/msdeploy_support/*.rb"].each do |path|
  require path
end

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

    private
    def define
      CLEAN.include(log_file)

      task @name do
        mkdir_p(File.dirname(log_file))

        cmd = [@msdeploy, MSDeploySupport::Mapper.map(@args)]

        run_with_redirected_output(cmd) do |ok, status_code, command, log|
          if ok
            puts 'Deployment successful.'
          else
            message = %Q(Deployment errors occurred, exit code #{status_code}. Please review #{log_file}.

10 last logged lines:
#{log}

Tried to execute:
#{command})

            raise Pipeline::ExecutionError.new(message)
          end
        end
      end

      self
    end

    def run_with_redirected_output(cmd)
      cmd = cmd.flatten.map {|c| MSDeploySupport::Mapper.quote(c) }.join(' ')
      puts cmd

      all_messages = StringIO.new
      begin
        stdout = -> (msg) { $stdout.puts msg.gsub(/\n/, '').green }
        stderr = -> (msg) { $stderr.puts msg.gsub(/\n/, '').bold.red }

        log = -> (msg) {
          File.open(log_file, 'a') { |f| f.write(msg) }

          all_messages.puts(msg)

          stdout = stderr if msg =~ /^(error|[\w\.]*exception)/i
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
  end
end
