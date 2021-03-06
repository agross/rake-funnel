module Rake
  module Funnel
    module Support
      module MSDeploy
        class RegistryPatch
          KEYS = [
            'SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3',
            'SOFTWARE\Wow6432Node\Microsoft\IIS Extensions\MSDeploy\3'
          ].freeze
          VERSION_VALUE = 'Version'.freeze
          FAKE_VERSION = '99.0.0.0'.freeze

          def initialize(&block)
            patch.apply!
            yield block if block_given?
          ensure
            patch.revert!
          end

          private

          def patch
            @patch ||= create_patch
          end

          def root
            ::Win32::Registry::HKEY_LOCAL_MACHINE
          end

          def delete_key(key)
            return nil unless key.created?

            keyname = key.keyname
            proc do
              root.create(File.dirname(keyname)) do |r|
                r.delete_key(File.basename(keyname), true)
              end
            end
          end

          def delete_value(key, value)
            keyname = key.keyname
            proc do
              root.create(keyname) do |r|
                r.delete_value(value)
              end
            end
          end

          def create_patch # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
            begin
              require 'win32/registry'
            rescue LoadError
              return Rake::Funnel::Support::Patch.new(self)
            end

            Rake::Funnel::Support::Patch.new(self) do |p|
              resets = []

              p.setup do
                begin
                  resets = KEYS.map do |key|
                    root.create(key) do |r|
                      begin
                        r[VERSION_VALUE]

                        delete_version = proc {}
                      rescue ::Win32::Registry::Error
                        r[VERSION_VALUE] = FAKE_VERSION

                        delete_version = delete_value(r, VERSION_VALUE)
                      end

                      delete_key(r) || delete_version
                    end
                  end
                rescue ::Win32::Registry::Error => e
                  $stderr.print "Could not patch registry to pretend MSDeploy is installed: #{e}\n"
                end
              end

              p.reset do
                resets.compact.each(&:call)
              end
            end
          end
        end
      end
    end
  end
end
