module Rake
  module Funnel
    module Support
      class BinaryVersionReader
        class << self
          KNOWN_ATTRIBUTES = %i(company_name
                                file_description
                                file_version
                                legal_copyright
                                product_name
                                product_version
                                assembly_version).freeze
          SEPARATOR = "\0".freeze
          TERMINATOR = "\0" * 3

          def read_from(assembly)
            binary = File.binread(assembly)

            attributes = KNOWN_ATTRIBUTES.map do |attr|
              read_attribute(binary, attr)
            end

            hash = attributes.inject({}) do |memo, attr|
              memo.merge(attr)
            end

            VersionInfo.new(hash)
          end

          private

          def read_attribute(binary, attr)
            binary_attr = attr.pascalize.gsub(/(.)/) { |match| match + SEPARATOR }

            data = binary.match(/#{binary_attr}#{SEPARATOR}+(.*?)#{TERMINATOR}/)
            return {} if data.nil?

            { attr.to_s => data[1].gsub(/#{SEPARATOR}/, '') }
          end
        end
      end
    end
  end
end
