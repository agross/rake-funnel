module Rake
  module Funnel
    module Support
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
        def create(sym, *args)
          return sym unless sym.is_a?(Symbol)

          begin
            type = self.class.module.const_get(sym)
          rescue NameError
            raise NameError, "Unknown type to instantiate: #{sym.inspect}. Available types are: #{available.inspect}"
          end

          type.new(*args)
        end

        def available
          self.class.module.constants.sort
        end
      end
    end
  end
end
