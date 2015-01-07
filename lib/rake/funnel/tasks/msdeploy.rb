require 'rake/clean'
require 'rake/tasklib'

Dir["#{File.dirname(__FILE__)}/msdeploy_support/*.rb"].each do |path|
  require path
end

module Rake::Funnel::Tasks
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
        mapper = Rake::Funnel::Support::Mapper.new(:MSDeploy)
        cmd = [quote(msdeploy), mapper.map(args)]
          .flatten
          .join(' ')

        MSDeploySupport::RegistryPatch.new do
          shell(cmd, log_file: log_file, error_lines: /^(error|[\w\.]*exception)/i)
        end
      end

      self
    end

    def quote(value)
      value = value.gsub(/"/, '""') if value.kind_of?(String)
      return %Q{"#{value}"} if value =~ /\s/
      value
    end
  end
end
