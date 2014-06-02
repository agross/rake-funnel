require 'smart_colored'
require 'smart_colored/extend'

module Rake::Funnel::Extensions
  module DisableColors
    def self.included(mod)
      original_apply_format = mod.instance_method(:apply_format)

      define_method(:apply_format) do |format|
        return self unless $stdout.tty?

        bind_to = self
        bind_to = SmartColored::String.new(self) if mod == SmartColored::String
        
        original_apply_format.bind(bind_to).call(format)
      end
    end
  end
end

class SmartColored::String
  include Rake::Funnel::Extensions::DisableColors
end

class String
  include Rake::Funnel::Extensions::DisableColors
end
