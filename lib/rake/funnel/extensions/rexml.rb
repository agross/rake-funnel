# frozen_string_literal: true

require 'rexml/document'

module Rake
  module Funnel
    module Extensions
      module REXML
        module Functions
          def lower_case(string)
            string(string).downcase
          end

          def matches(string, test)
            File.fnmatch?(test, string(string), File::FNM_CASEFOLD)
          end
        end
      end
    end
  end
end

module REXML
  module Functions
    extend Rake::Funnel::Extensions::REXML::Functions

    Rake::Funnel::Extensions::REXML::Functions.public_instance_methods.each do |method|
      singleton_method_added(method)
    end
  end
end
