require 'rake/clean'
require 'rake/tasklib'

module Rake::Funnel::Tasks
  class Copy < Rake::TaskLib
    include Rake::Funnel::Support

    attr_accessor :name, :source, :target

    def initialize(name = :copy)
      @name = name

      @source = []
      @target = nil

      yield self if block_given?
      define
    end

    private
    def define
      target && CLEAN.include(target)

      desc "Copy #{files.join(', ')} to #{target}"
      task name do
        raise 'Target not defined' unless target

        files.each do |source|
          next if File.directory?(source)

          target = target_path(source)

          dir = File.dirname(target)
          RakeFileUtils.mkdir_p(dir) unless File.directory?(dir)

          RakeFileUtils.cp(source, target, { preserve: true})
        end
      end

      self
    end

    def files
      Finder.new(source, self, 'No files found.').all_or_default
    end

    def target_path(file)
      target_relative = Pathname.new(file).relative_path_from(Pathname.new(common_path)).to_s
      File.join(target, target_relative)
    end

    def common_path
      @common_path ||= files.common_path
    end
  end
end
