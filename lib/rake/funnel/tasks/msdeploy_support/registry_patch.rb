require 'win32/registry'

module Rake::Funnel::Tasks::MSDeploySupport
  class RegistryPatch
    Key = 'SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3'
    VersionValue = 'Version'
    FakeVersion = '99.0.0.0'

    def initialize(&block)
      begin
        patch.apply!
        yield block
      ensure
        patch.revert!
      end
    end

    private
    def patch
      @patch ||= create_patch
    end

    def create_patch
      Rake::Funnel::Support::Patch.new(self) do |p|
        key_created = false
        version_created = false

        p.setup do
          Win32::Registry::HKEY_LOCAL_MACHINE.create(Key) do |r|
            key_created = r.created?

            begin
              r[VersionValue]
            rescue Win32::Registry::Error
              r[VersionValue] = FakeVersion
              version_created = true
            end
          end
        end

        p.reset do
          if (key_created)
            Win32::Registry::HKEY_LOCAL_MACHINE.create(File.dirname(Key)) do |r|
              r.delete_key(File.basename(Key), true)
            end
          elsif (version_created)
            Win32::Registry::HKEY_LOCAL_MACHINE.create(Key) do |r|
              r.delete_value(VersionValue)
            end
          end
        end
      end
    end
  end
end
