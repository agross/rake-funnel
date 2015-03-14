module Rake::Funnel::Support
  class Copier
    class << self
      def copy(files, target)
        raise 'Target not defined' unless target

        common_path = files.common_path
        files.each do |source|
          next if File.directory?(source)

          target_path = target_path(source, common_path, target)

          dir = File.dirname(target_path)
          RakeFileUtils.mkdir_p(dir) unless File.directory?(dir)

          RakeFileUtils.cp(source, target_path, { preserve: true })
        end
      end

      private
      def target_path(file, common_path, target)
        target_relative = Pathname.new(file).relative_path_from(Pathname.new(common_path)).to_s
        File.join(target, target_relative)
      end
    end
  end
end
