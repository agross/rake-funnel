module Rake::Funnel::Support
  class Mono
    class << self
      def invocation(command, *args)
        cmd_args = ([command] << args).flatten

        if Rake::Win32.windows?
          return command if cmd_args.count == 1
          return cmd_args
        end

        cmd_args.unshift('mono')
      end
    end
  end
end
