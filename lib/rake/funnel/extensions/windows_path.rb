module Rake::Funnel::Extensions
  module WindowsPath
    def to_windows_path
      self.gsub(%r|/|, '\\')
    end
  end
end

class String
  include Rake::Funnel::Extensions::WindowsPath
end
