module Rake::Funnel::Support
  class Mono
    class << self
      def invocation(executable, *args)
        exe_args = ([executable] << args).flatten.compact

        if Rake::Win32.windows?
          return exe_args
        end

        exe_args.unshift('mono', which(exe_args.shift))
      end

      private
      def which(executable)
        return executable if File.exists?(executable)

        ENV['PATH']
          .split(File::PATH_SEPARATOR)
          .map { |path| File.join(path, executable) }
          .select { |path| File.exists?(path) }
          .first || executable
      end
    end
  end
end
