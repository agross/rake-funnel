# frozen_string_literal: true

module Rake
  module Funnel
    module Extensions
      module Case
        module CamelCase
          def camelize
            to_s
              .split('_')
              .inject([]) { |buffer, e| buffer.push(buffer.empty? ? e : e.capitalize) }
              .join
          end
        end
      end
    end
  end
end

class String
  include Rake::Funnel::Extensions::Case::CamelCase
end

class Symbol
  include Rake::Funnel::Extensions::Case::CamelCase
end
