# frozen_string_literal: true

require 'open3'

module Rake
  module Funnel
    module Support
      module MSBuild
        class BuildTool
          class << self
            def find
              vswhere ||
                from_registry ||
                mono ||
                raise('No compatible MSBuild build tool was found')
            end

            private

            def mono
              out, status = Open3.capture2('mono', '--version')
              unless status.success?
                $stderr.print "Could not determine mono version: #{status}\n"
                return nil
              end

              return 'msbuild' if out[/^Mono JIT compiler version ([\d\.]+)/, 1] >= '5.0'

              'xbuild'
            rescue Errno::ENOENT
              nil
            end

            def vswhere # rubocop:disable Metrics/MethodLength
              # -products * is required.
              # https://github.com/Microsoft/vswhere/issues/61#issuecomment-298691077
              args = %w(vswhere.exe
                        -products *
                        -latest
                        -requires Microsoft.Component.MSBuild
                        -property installationPath)

              path, status = Open3.capture2(*args)
              unless status.success?
                $stderr.print "vswhere failed: #{status}\n"
                return nil
              end

              Dir[File.join(Rake::Win32.normalize(path.strip),
                            'MSBuild/*/Bin/MSBuild.exe')]
                .find { |e| File.file?(e) }
            rescue Errno::ENOENT
              nil
            end

            KEY = 'SOFTWARE\Microsoft\MSBuild\ToolsVersions'.freeze
            REGISTRY_VERSIONS = %w(14.0 12.0 4.0 3.5 2.0).freeze

            def from_registry
              return nil unless require_registry

              candidates = REGISTRY_VERSIONS.map do |version|
                version_key(version) do |reg|
                  candidate = File.join(reg['MSBuildToolsPath'] || '', 'msbuild.exe')
                  next candidate if File.exist?(candidate)
                end
              end

              candidates.compact.first
            end

            def require_registry
              require 'win32/registry'
              true
            rescue LoadError
              false
            end

            def version_key(version)
              key = KEY + '\\' + version

              ::Win32::Registry::HKEY_LOCAL_MACHINE.open(key) do |reg|
                yield(reg) if block_given?
              end
            rescue ::Win32::Registry::Error
              nil
            end
          end
        end
      end
    end
  end
end
