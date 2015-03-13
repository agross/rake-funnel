module Rake::Funnel::Support::AssemblyVersion
  class FromVersionFiles
    include Rake::Funnel::Support
    include Enumerable

    attr_reader :search_pattern, :build_number, :sha

    def initialize(args = {})
      @search_pattern = args[:search_pattern] || %w(**/VERSION)
      @build_number = args[:build_number]
      @sha = args[:sha]
    end

    def each
      block_given? or return enum_for(__method__)

      files.each do |file|
        Rake.rake_output_message("Reading #{file}")

        version_info = VersionInfo.parse({
            version: VersionInfo.read_version_from(file),
            build_number: build_number,
            sha: sha
          })

        yield({ source: file, version_info: version_info })
      end
    end

    private
    def files
      Finder.new(search_pattern, self, 'No version files found.').all_or_default
    end
  end
end
