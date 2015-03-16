module Rake
  module Funnel
    module Extensions
      module WindowsPath
        def to_windows_path
          gsub(%r|/|, '\\')
        end
      end
    end
  end
end

class String
  include Rake::Funnel::Extensions::WindowsPath
end
