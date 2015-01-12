include Rake::Funnel::Tasks::MSDeploySupport

describe RegistryPatch do
  describe 'execution' do
    it 'should yield block' do
      result = 0

      described_class.new do
        result = 42
      end

      expect(result).to eq(42)
    end

    it 'should work without block' do
      expect(lambda { described_class.new }).not_to raise_error
    end
  end

  describe 'patching' do
    context 'not on Windows' do
      before {
        allow_any_instance_of(described_class).to receive(:require).with('win32/registry').and_raise(LoadError)
      }

      it 'should succeed' do
        expect(lambda { described_class.new }).not_to raise_error
      end
    end

    context 'on Windows' do
      before {
        allow_any_instance_of(described_class).to receive(:require).with('win32/registry')
      }

      context 'MSDeploy registry key and "Version" value does not exist', platform: :win32 do
        let(:key) {
          k = instance_double(Win32::Registry)
          allow(k).to receive(:created?).and_return(true)
          allow(k).to receive(:[]).and_raise(Win32::Registry::Error.new(42))
          allow(k).to receive(:[]=)
          allow(k).to receive(:delete_key)
          k
        }

        before {
          allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:create).and_yield(key)
        }

        before {
          described_class.new
        }

        it 'should create the key' do
          expect(Win32::Registry::HKEY_LOCAL_MACHINE).to have_received(:create).with(RegistryPatch::Key)
        end

        it 'should create the version' do
          expect(key).to have_received(:[]=).with('Version', RegistryPatch::FakeVersion)
        end

        it 'should delete the key' do
          expect(key).to have_received(:delete_key).with('3', true)
        end
      end

      context 'MSDeploy registry key does exist', platform: :win32 do
        before {
          allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:create).and_yield(key)
        }

        before {
          described_class.new
        }

        context '"Version" value does not exist' do
          let(:key) {
            k = instance_double(Win32::Registry)
            allow(k).to receive(:created?).and_return(false)
            allow(k).to receive(:[]).and_raise(Win32::Registry::Error.new(42))
            allow(k).to receive(:[]=)
            allow(k).to receive(:delete_value)
            k
          }

          it 'should create the version' do
            expect(key).to have_received(:[]=).with('Version', RegistryPatch::FakeVersion)
          end

          it 'should delete the version' do
            expect(key).to have_received(:delete_value).with(RegistryPatch::VersionValue)
          end
        end

        context '"Version" value does exist' do
          let(:key) {
            k = instance_double(Win32::Registry)
            allow(k).to receive(:created?).and_return(false)
            allow(k).to receive(:[])
            k
          }

          it 'should do nothing' do
            expect(true).to eq(true)
          end
        end
      end
    end
  end
end
