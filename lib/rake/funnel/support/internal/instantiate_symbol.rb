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

          found = [sym, sym.pascalize.to_sym]
            .select { |candidate| mod.constants.include?(candidate) }
            .first

          raise NameError, "Unknown type to instantiate: #{sym.inspect}. Available types are: #{available.inspect}" if found.nil?

          type = mod.const_get(found)
          type.new(*args)
        end

        def available
          mod.constants.sort
        end

        def mod
          self.class.module
        end
      end
    end
  end
end
