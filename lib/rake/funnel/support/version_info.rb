require 'ostruct'

module Rake::Funnel::Support
  class VersionInfo < OpenStruct
    include Enumerable

    def initialize(hash = nil)
      super(hash)
      freeze
    end

    def each(&block)
      each_pair(&block)
    end

    class << self
      def parse(context)
        VersionInfo.new({
            assembly_version: assembly_version(context),
            assembly_file_version: assembly_file_version(context),
            assembly_informational_version: assembly_informational_version(context)
          })
      end

      def read_version_from(file)
        File.open(file, &:readline).strip
      end

      private
      def default_version(context)
        context[:version] || '0'
      end

      def assembly_version(context)
        strip_trailing_non_numeric(default_version(context))
      end

      def assembly_file_version(context)
        numeric_build_number = strip_leading_non_numeric(context[:build_number])

        [
          assembly_version(context),
          numeric_build_number
        ].compact.join('.')
      end

      def assembly_informational_version(context)
        build_number = context[:build_number]
        join_using = '.'
        join_using = '' if build_number =~ /^\D/

        prefix = [default_version(context), build_number].compact.join(join_using)
        sha = context[:sha]

        [prefix, sha].compact.join('-')
      end

      def strip_trailing_non_numeric(str)
        return nil if str.nil?
        str.to_s.gsub(/[^\d\.].*/, '')
      end

      def strip_leading_non_numeric(str)
        return nil if str.nil?
        str = str.to_s.gsub(/[^\d\.]/, '')

        return nil if str.empty?
        str
      end
    end
  end
end
