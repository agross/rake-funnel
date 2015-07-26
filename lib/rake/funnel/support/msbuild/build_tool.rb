module Rake
  module Funnel
    module Support
      module MSBuild
        class BuildTool
          class << self
            def find
              return 'xbuild' unless Rake::Win32.windows?

              require 'win32/registry'

              %w(14.0 12.0 4.0 3.5 2.0).collect { |version|
                key = "SOFTWARE\\Microsoft\\MSBuild\\ToolsVersions\\#{version}"

                begin
                  ::Win32::Registry::HKEY_LOCAL_MACHINE.open(key) do |reg|
                    candidate = File.join(reg['MSBuildToolsPath'] || '', 'msbuild.exe')
                    next candidate if File.exist?(candidate)
                  end
                rescue
                  next
                end
              }.compact.first
            end
          end
        end
      end
    end
  end
end
