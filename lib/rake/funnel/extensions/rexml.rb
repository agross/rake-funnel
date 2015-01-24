require 'rexml/document'

module Rake::Funnel::Extensions
  module REXML
    module Functions
      def lower_case(string)
        string.first.to_s.downcase
      end

      def matches(string, test)
        File.fnmatch?(test, string.first.to_s, File::FNM_CASEFOLD)
      end
    end
  end
end

module REXML
  module Functions
    class << self
      include Rake::Funnel::Extensions::REXML::Functions
    end
  end
end
