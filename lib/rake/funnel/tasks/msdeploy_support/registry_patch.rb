module Rake::Funnel::Tasks::MSDeploySupport
  class RegistryPatch
    KEY = 'SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3'
    VERSION_VALUE = 'Version'
    FAKE_VERSION = '99.0.0.0'

    def initialize(&block)
      begin
        patch.apply!
        yield block if block_given?
      ensure
        patch.revert!
      end
    end

    private
    def patch
      @patch ||= create_patch
    end

    def create_patch
      begin
        require 'win32/registry'
      rescue LoadError
        return Rake::Funnel::Support::Patch.new(self)
      end

      Rake::Funnel::Support::Patch.new(self) do |p|
        key_created = false
        version_created = false

        p.setup do
          Win32::Registry::HKEY_LOCAL_MACHINE.create(KEY) do |r|
            key_created = r.created?

            begin
              r[VERSION_VALUE]
            rescue Win32::Registry::Error
              r[VERSION_VALUE] = FAKE_VERSION
              version_created = true
            end
          end
        end

        p.reset do
          if (key_created)
            Win32::Registry::HKEY_LOCAL_MACHINE.create(File.dirname(KEY)) do |r|
              r.delete_key(File.basename(KEY), true)
            end
          elsif (version_created)
            Win32::Registry::HKEY_LOCAL_MACHINE.create(KEY) do |r|
              r.delete_value(VERSION_VALUE)
            end
          end
        end
      end
    end
  end
end
