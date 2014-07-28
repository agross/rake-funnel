include Rake::Funnel::Tasks::MSDeploySupport

describe RegistryPatch do

  describe 'execution' do
    it 'should yield' do
      result = 0

      described_class.new do
        result = 42
      end

      expect(result).to eq(42)
    end
  end

  describe 'patching', platform: :win32 do
    context 'MSDeploy registry key and "Version" value does not exist' do
      let(:key){
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
        described_class.new { nil }
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

    context 'MSDeploy registry key does exist' do
      before {
        allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:create).and_yield(key)
      }

      before {
        described_class.new { nil }
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
