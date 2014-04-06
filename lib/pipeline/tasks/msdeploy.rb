require 'rake/clean'
require 'rake/tasklib'

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
        cmd = [MSDeploySupport::Mapper.quote(@msdeploy), MSDeploySupport::Mapper.map(@args)]
          .flatten
          .join(' ')

        shell(cmd, log_file: log_file, error_lines: /^(error|[\w\.]*exception)/i)
      end

      self
    end
  end
end
