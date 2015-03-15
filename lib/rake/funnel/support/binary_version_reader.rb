module Rake::Funnel::Support
  class BinaryVersionReader
    class << self
      KNOWN_ATTRIBUTES = [:company_name, :file_description, :file_version, :legal_copyright, :product_name, :product_version, :assembly_version]
      SEPARATOR = "\0"
      TERMINATOR = "\0" * 3

      def read_from(assembly)
        binary = File.binread(assembly)

        hash = KNOWN_ATTRIBUTES.map { |attr|
          read_attribute(binary, attr)
        }
        .inject({}) { |memo, attr|
          memo.merge(attr)
        }

        VersionInfo.new(hash)
      end

      private
      def read_attribute(binary, attr)
        binary_attr = attr.pascalize.gsub(/(.)/) { |match| match + SEPARATOR }

        data = binary.match(/#{binary_attr}#{SEPARATOR}+(.*?)#{TERMINATOR}/)
        return {} if data.nil?

        { "#{attr}" => data[1].gsub(/#{SEPARATOR}/, '') }
      end
    end
  end
end
