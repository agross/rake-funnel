module Rake::Funnel::Support
  module InstantiateSymbol
    def self.included(klass)
      klass.extend(ClassMethods)
      klass.send(:instantiate, klass)
    end

    module ClassMethods
      attr_reader :module

      private
      def instantiate(mod)
        @module = mod
      end
    end

    private
    def create(sym)
      return sym unless sym.kind_of?(Symbol)

      begin
        type = self.class.module.const_get(sym)
      rescue NameError
        raise NameError, "Unknown type to instantiate: #{sym.inspect}. Available types are: #{available.inspect}"
      end

      type.new
    end

    def available
      return self.class.module.constants.sort
    end
  end
end
