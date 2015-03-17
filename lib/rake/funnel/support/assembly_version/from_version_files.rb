module Rake
  module Funnel
    module Support
      module AssemblyVersion
        class FromVersionFiles
          include Rake::Funnel::Support
          include Enumerable

          attr_reader :search_pattern, :metadata

          def initialize(args = {})
            @search_pattern = args[:search_pattern] || %w(**/VERSION)
            @metadata = args[:metadata]
          end

          def each
            block_given? or return enum_for(__method__)

            files.each do |file|
              Rake.rake_output_message("Reading #{file}")

              version_info = VersionInfo.parse(
                version: VersionInfo.read_version_from(file),
                metadata: metadata
              )

              yield({ source: file, version_info: version_info })
            end
          end

          private
          def files
            Finder.new(search_pattern, self, 'No version files found.').all_or_default
          end
        end
      end
    end
  end
end
