require 'ostruct'

module Rake
  module Funnel
    module Support
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
            context[:version].to_s || '0'
          end

          def pad(version, parts)
            numerics = version.split('.').take(parts).map { |part| part.to_i }

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
            build_number = numeric(context[:build_number])
            return version.sub(/\.0$/, ".#{build_number}") if build_number
            version
          end

          def numeric(str)
            return str if str.to_s =~ /^\d+$/
            nil
          end

          def assembly_informational_version(context)
            version = default_version(context)
            numeric_version = pad(version, 3)
            alpha_version = version.sub(/^[\d\.]*/, '')

            numeric_build_number = numeric(context[:build_number])
            unless numeric_build_number
              alpha_build_number = context[:build_number]
              if alpha_build_number && alpha_build_number !~ /^-/
                alpha_build_number = '-' + alpha_build_number
              end
            end

            semver = [
              numeric_version,
              alpha_version,
              alpha_build_number
            ].join

            metadata = [
              numeric_build_number ? 'build' : nil,
              numeric_build_number,
              context[:sha] ? 'sha' : nil,
              context[:sha]
            ].compact.join('.')

            [
              semver,
              metadata.empty? ? nil : metadata
            ].compact.join('+')
          end
        end
      end
    end
  end
end
