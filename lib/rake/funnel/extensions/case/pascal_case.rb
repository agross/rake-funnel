module Rake
  module Funnel
    module Extensions
      module Case
        module PascalCase
          def pascalize
            to_s
              .split('_')
              .inject([]) { |buffer, e| buffer.push(e.slice(0, 1).capitalize + e.slice(1..-1)) }
              .join
          end
        end
      end
    end
  end
end

class String
  include Rake::Funnel::Extensions::Case::PascalCase
end

class Symbol
  include Rake::Funnel::Extensions::Case::PascalCase
end
