module Rake::Funnel::Support
  class Mono
    class << self
      def invocation(executable, *args)
        exe_args = ([executable] << args).flatten

        if Rake::Win32.windows?
          return executable if exe_args.count == 1
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
          .first
      end
    end
  end
end
