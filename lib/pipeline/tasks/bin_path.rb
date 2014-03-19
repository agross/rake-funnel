require 'rake/tasklib'

module Pipeline::Tasks
  class BinPath < Rake::TaskLib
    attr_accessor :name, :pattern

    def initialize(name = :bin_path)
      @name = name
      @pattern = ['tools/*', 'tools/*/bin']

      yield self if block_given?
      define
    end

    private
    def define
      task @name do
        add_pattern_to_path_environment
      end

      self
    end

    def add_pattern_to_path_environment
      bin_paths = Dir[*@pattern].map { |path| File.expand_path(path) }
      bin_paths << ENV['PATH']

      ENV['PATH'] = bin_paths.join(File::PATH_SEPARATOR)
    end
  end
end
