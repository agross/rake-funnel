module Rake
  module Funnel
    module Support
      class Which
        class << self
          def which(executable)
            return executable if File.file?(executable)

            ENV['PATH']
              .split(File::PATH_SEPARATOR)
              .map { |path| File.join(path, executable) }
              .select { |path| File.file?(path) }
              .first
          end
        end
      end
    end
  end
end
