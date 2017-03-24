describe Rake::Funnel::Support::MSDeploy::RegistryPatch do
  before {
    allow_any_instance_of(described_class).to receive(:warn)
  }

  describe 'execution' do
    it 'should yield block' do
      result = 0

      described_class.new do
        result = 42
      end

      expect(result).to eq(42)
    end

    it 'should work without block' do
      expect { described_class.new }.not_to raise_error
    end
  end

  describe 'patching' do
    context 'not on Windows' do
      before {
        allow_any_instance_of(described_class).to receive(:require).with('win32/registry').and_raise(LoadError)
      }

      it 'should succeed' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context 'on Windows', skip: ('Windows Registry not available' unless defined?(::Win32::Registry)) do
      let(:root) { Win32::Registry::HKEY_LOCAL_MACHINE }

      let(:keys) {
        described_class::KEYS.map do |key|
          instance_double(Win32::Registry, keyname: key)
        end
      }

      def allow_open_or_create(key)
        allow(root).to receive(:create).with(key.keyname).and_yield(key)
      end

      def allow_open_for_deletion(key)
        allow(root).to receive(:create).with(File.dirname(key.keyname)).and_yield(key)
      end

      context 'MSDeploy registry key and "Version" value does not exist' do
        before {
          keys.each do |key|
            allow(key).to receive(:created?).and_return(true)
            allow(key).to receive(:[]).and_raise(Win32::Registry::Error.new('value does not exist, so getting it raises'.length))
            allow(key).to receive(:[]=)
            allow(key).to receive(:delete_key)
          end
        }

        before {
          keys.each do |key|
            allow_open_or_create(key)
            allow_open_for_deletion(key)
          end
        }

        before {
          described_class.new
        }

        it 'should create the key' do
          keys.each do |key|
            expect(root).to have_received(:create).with(key.keyname)
          end
        end

        it 'should create the version' do
          keys.each do |key|
            expect(key).to have_received(:[]=).with('Version', described_class::FAKE_VERSION)
          end
        end

        it 'should delete the key' do
          keys.each do |key|
            expect(key).to have_received(:delete_key).with(File.basename(key.keyname), true)
          end
        end
      end

      context 'registry access is denied' do
        before {
          allow(root).to receive(:create).and_raise(::Win32::Registry::Error.new(5))
        }

        before {
          described_class.new
        }

        it 'should warn' do
          expect(subject).to have_received(:warn).with(/Could not patch registry to pretend MSDeploy is installed/)
        end
      end

      context 'MSDeploy registry key does exist' do
        before {
          keys.each do |key|
            allow_open_or_create(key)
          end
        }

        context '"Version" value does not exist' do
          before {
            keys.each do |key|
              allow(key).to receive(:created?).and_return(false)
              allow(key).to receive(:[]).and_raise(Win32::Registry::Error.new('value does not exist, so getting it raises'.length))
              allow(key).to receive(:[]=)
              allow(key).to receive(:delete_value)
            end
          }

          before {
            described_class.new
          }

          it 'should create the version' do
            keys.each do |key|
              expect(key).to have_received(:[]=).with('Version', described_class::FAKE_VERSION)
            end
          end

          it 'should delete the version' do
            keys.each do |key|
              expect(key).to have_received(:delete_value).with(described_class::VERSION_VALUE)
            end
          end
        end

        context '"Version" value does exist' do
          before {
            keys.each do |key|
              allow(key).to receive(:created?).and_return(false)
              allow(key).to receive(:[])
            end
          }

          before {
            described_class.new
          }

          it 'should do nothing' do
            expect(true).to eq(true)
          end
        end
      end
    end
  end
end
