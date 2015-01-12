require 'pathname'
require 'rake/tasklib'
require 'zip'

module Rake::Funnel::Tasks
  class Zip < Rake::TaskLib
    attr_accessor :name, :source, :target, :zip_root

    def initialize(name = :package)
      @name = name

      @source = []
      @target = nil
      @zip_root = nil

      yield self if block_given?
      define
    end

    private
    def define
      target && CLEAN.include(target)

      desc "Zip #{files.join(', ')} to #{target}"
      task name do
        raise 'Target not defined' unless target

        RakeFileUtils.mkdir_p(File.dirname(target))

        configure_zip
        create_zip(files, target)

        Rake.rake_output_message("Created #{target}")
      end

      self
    end

    def files
      Rake::Funnel::Support::Finder.new(source, self, 'No files to zip.').all_or_default
    end

    def configure_zip
      ::Zip.unicode_names = true
      ::Zip.default_compression = Zlib::BEST_COMPRESSION
    end

    def create_zip(files, target)
      ::Zip::File.open(target, ::Zip::File::CREATE) do |zip|
        common_path = files.common_path

        files.each do |file|
          zipped_file = get_zipped_path(common_path, file)

          zip.add(zipped_file, file)
        end
      end
    end

    def get_zipped_path(common_path, file)
      file = Pathname.new(file).relative_path_from(Pathname.new(common_path)).to_s unless common_path.nil?
      file = File.join(zip_root, file) unless zip_root.nil? || zip_root.empty?
      file
    end
  end
end
