require 'pathname'
require 'zip'

module Rake::Funnel::Support
  class Zipper
    class << self
      def zip(files, target, zip_root = nil)
        raise 'Target not defined' unless target

        target_dir = File.dirname(target)
        RakeFileUtils.mkdir_p(target_dir) unless File.directory?(target_dir)

        configure_zip
        create_zip(files || [], target, zip_root)
      end

      private
      def configure_zip
        ::Zip.unicode_names = true
        ::Zip.default_compression = Zlib::BEST_COMPRESSION
      end

      def create_zip(files, target, zip_root)
        ::Zip::File.open(target, ::Zip::File::CREATE) do |zip|
          common_path = files.common_path

          files.each do |file|
            zipped_file = get_zipped_path(common_path, file, zip_root)

            entry = zip.add(zipped_file, file)
            set_mtime(entry, file)
          end
        end
      end

      def get_zipped_path(common_path, file, zip_root)
        file = Pathname.new(file).relative_path_from(Pathname.new(common_path)).to_s unless common_path.nil?
        file = File.join(zip_root, file) unless zip_root.nil? || zip_root.empty?
        file
      end

      # To work around this bug: https://github.com/rubyzip/rubyzip/issues/176
      def set_mtime(entry, file)
        entry.time = ::Zip::DOSTime.at(File.mtime(file))
        entry.extra.delete('UniversalTime')
      end
    end
  end
end
