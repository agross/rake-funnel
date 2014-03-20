module Pipeline::Patches
  module CamelCase
    def camelize
      self
        .to_s
        .split('_')
        .inject([]) { |buffer, e| buffer.push(buffer.empty? ? e : e.capitalize) }
        .join
    end
  end
end

class String
  include Pipeline::Patches::CamelCase
end

class Symbol
  include Pipeline::Patches::CamelCase
end
