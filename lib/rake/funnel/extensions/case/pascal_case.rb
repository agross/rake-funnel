module Rake::Funnel::Extensions
  module PascalCase
    def pascalize
      self
        .to_s
        .split('_')
        .inject([]) { |buffer, e| buffer.push(e.slice(0, 1).capitalize + e.slice(1..-1)) }
        .join
    end
  end
end

class String
  include Rake::Funnel::Extensions::PascalCase
end

class Symbol
  include Rake::Funnel::Extensions::PascalCase
end
