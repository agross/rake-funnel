module Rake
  module Funnel
    module Support
      class Mono
        class << self
          def invocation(executable, *args)
            exe_args = ([executable] << args).flatten.compact

            return exe_args if Rake::Win32.windows?

            executable = exe_args.shift
            found = Which.which(executable) || executable
            exe_args.unshift('mono', found)
          end
        end
      end
    end
  end
end
