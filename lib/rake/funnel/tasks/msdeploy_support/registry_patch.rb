module Rake::Funnel::Tasks::MSDeploySupport
  class RegistryPatch
    KEYS = [
      'SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3',
      'SOFTWARE\Wow6432Node\Microsoft\IIS Extensions\MSDeploy\3'
    ]
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

    def root
      Win32::Registry::HKEY_LOCAL_MACHINE
    end

    def delete_key(key)
      return nil unless key.created?

      Proc.new {
        root.create(File.dirname(key.keyname)) do |r|
          r.delete_key(File.basename(key.keyname), true)
        end
      }
    end

    def delete_value(key, value)
      Proc.new {
        root.create(key.keyname) do |r|
          r.delete_value(value)
        end
      }
    end

    def create_patch
      begin
        require 'win32/registry'
      rescue LoadError
        return Rake::Funnel::Support::Patch.new(self)
      end

      Rake::Funnel::Support::Patch.new(self) do |p|
        resets = []

        p.setup do
          resets = KEYS.map do |key|
            root.create(key) do |r|
              begin
                r[VERSION_VALUE]

                delete_version = Proc.new {}
              rescue Win32::Registry::Error
                r[VERSION_VALUE] = FAKE_VERSION

                delete_version = delete_value(r, VERSION_VALUE)
              end

              delete_key(r) || delete_version
            end
          end
        end

        p.reset do
          resets.compact.each do |reset|
            reset.call
          end
        end
      end
    end
  end
end
