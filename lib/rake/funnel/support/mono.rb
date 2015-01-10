module Rake::Funnel::Support
  class Mono
    class << self
      def invocation(executable, *args)
        exe_args = ([executable] << args).flatten.compact

        if Rake::Win32.windows?
          return exe_args
        end

        executable = exe_args.shift
        found = Which.which(executable) || executable
        exe_args.unshift('mono', found)
      end
    end
  end
end
