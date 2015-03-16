require 'smart_colored'
require 'smart_colored/extend'

module Rake
  module Funnel
    module Extensions
      module DisableColors
        def self.included(klass)
          original_apply_format = klass.instance_method(:apply_format)

          define_method(:apply_format) do |format|
            return self unless $stdout.tty?

            bind_to = self
            bind_to = SmartColored::String.new(self) if klass == SmartColored::String

            original_apply_format.bind(bind_to).call(format)
          end
        end
      end
    end
  end
end

module SmartColored
  class String
    include Rake::Funnel::Extensions::DisableColors
  end
end

class String
  include Rake::Funnel::Extensions::DisableColors
end
