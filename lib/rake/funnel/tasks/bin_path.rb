require 'rake/tasklib'

module Rake::Funnel::Tasks
  class BinPath < Rake::TaskLib
    attr_accessor :name, :pattern

    def initialize(name = :bin_path)
      @name = name
      @pattern = %w(tools/* tools/*/bin packages/**/tools)

      yield self if block_given?
      define
    end

    private
    def define
      task @name do
        puts 'Added the following paths to the PATH environment variable:'
        add_pattern_to_path_environment.each do |p|
          puts "  - #{p}"
        end
      end

      self
    end

    def add_pattern_to_path_environment
      bin_paths = Dir[*@pattern].map { |path| File.expand_path(path) }

      ENV['PATH'] = ([] << bin_paths << ENV['PATH']).flatten.join(File::PATH_SEPARATOR)
      bin_paths
    end
  end
end
