module Rake::Funnel::Support::MSBuild
  class BuildTool
    class << self
      def find
        if Rake::Win32.windows?
          require 'win32/registry'

          %w{12.0 4.0 3.5 2.0}.collect { |version|
            msbuild = nil
            key = "SOFTWARE\\Microsoft\\MSBuild\\ToolsVersions\\#{version}"

            begin
              Win32::Registry::HKEY_LOCAL_MACHINE.open(key) do |reg|
                candidate = "#{reg['MSBuildToolsPath']}\\msbuild.exe"
                msbuild = candidate if File.exists?(candidate)
              end
            rescue
            end

            msbuild
          }.compact.first
        else
          'xbuild'
        end
      end
    end
  end
end
