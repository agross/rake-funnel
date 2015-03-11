require 'rake/clean'
require 'rake/tasklib'

module Rake::Funnel::Tasks
  class MSDeploy < Rake::TaskLib
    include Rake::Funnel::Support
    include Rake::Funnel::Support::MSDeploy

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

      desc "Deploy #{deploy_source(args)}"
      task @name do
        mapper = Mapper.new(:MSDeploy)
        cmd = [quote(msdeploy), mapper.map(args)]
          .flatten
          .join(' ')

        RegistryPatch.new do
          shell(cmd, log_file: log_file, error_lines: /^(error|[\w\.]*exception)/i)
        end
      end

      self
    end

    def deploy_source(args)
      source = (args || {}).fetch(:source, {})
      path = source.first
      return if path.nil?

      Pathname.new(path[1]).relative_path_from(Pathname.new('.').realpath) rescue path[1]
    end

    def quote(value)
      value = value.gsub(/"/, '""') if value.kind_of?(String)
      return %Q{"#{value}"} if value =~ /\s/
      value
    end
  end
end
