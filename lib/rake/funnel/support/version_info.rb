require 'ostruct'

module Rake
  module Funnel
    module Support
      class VersionInfo < OpenStruct
        include Enumerable

        def initialize(hash = nil)
          super(hash)
        end

        def each(&block)
          each_pair(&block)
        end

        class << self
          def parse(context)
            VersionInfo.new(assembly_version: assembly_version(context),
                            assembly_file_version: assembly_file_version(context),
                            assembly_informational_version: assembly_informational_version(context))
          end

          def read_version_from(file)
            File.open(file, &:readline).strip
          end

          private

          def default_version(context)
            context[:version].to_s || '0'
          end

          def pad(version, parts)
            numerics = version.split('.').take(parts).map(&:to_i)

            template = Array.new(parts) { 0 }.map.with_index do |part, index|
              numerics[index] || part
            end
            template.join('.')
          end

          def assembly_version(context)
            version = default_version(context)
            pad(version, 4)
          end

          def assembly_file_version(context)
            version = assembly_version(context)
            build_number = numeric(context.fetch(:metadata, {})[:build])
            return version.sub(/\.0$/, ".#{build_number}") if build_number
            version
          end

          def numeric(str)
            return str if str.to_s =~ /^\d+$/
            nil
          end

          def assembly_informational_version(context) # rubocop:disable Metrics/MethodLength
            version = default_version(context)
            numeric_version = pad(version, 3)
            alpha_version = version.sub(/^[\d\.]*/, '')

            semver = [
              numeric_version,
              alpha_version,
              pre(context)
            ].join

            [
              semver,
              metadata(context)
            ].compact.join('+')
          end

          def pre(context)
            pre = context.fetch(:metadata, {})[:pre]
            pre = "-#{pre}" if pre && pre.to_s !~ /^-/

            pre
          end

          def metadata(context)
            metadata = context.fetch(:metadata, {}).reject { |k, _| k == :pre }

            metadata = metadata.map do |key, value|
              [key.to_s, value.to_s] if value
            end.compact

            return nil if metadata.empty?
            metadata.join('.')
          end
        end
      end
    end
  end
end
