require 'open3'

module Rake
  module Funnel
    module Support
      module MSBuild
        class BuildTool
          class << self
            def find
              mono_build || from_registry.compact.first
            end

            private

            def mono_build
              return nil if Rake::Win32.windows?

              begin
                out, status = Open3.capture2('mono', '--version')
                raise "Could not determine mono version: #{status}" unless status.success?
              rescue Errno::ENOENT
                raise 'mono is not installed'
              end

              return 'msbuild'.freeze if out[/^Mono JIT compiler version ([\d\.]+)/, 1] >= '5.0'

              'xbuild'.freeze
            end

            KEY = 'SOFTWARE\Microsoft\MSBuild\ToolsVersions'.freeze

            def from_registry
              return nil unless require_registry

              versions.map do |version|
                version_key(version) do |reg|
                  candidate = File.join(reg['MSBuildToolsPath'] || '', 'msbuild.exe')
                  next candidate if File.exist?(candidate)
                end
              end
            end

            def versions
              %w(14.0 12.0 4.0 3.5 2.0)
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
