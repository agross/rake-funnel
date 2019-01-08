# frozen_string_literal: true

describe Rake::Funnel::Support::Environments::Loader do
  let(:store) do
    double(Configatron::RootStore).as_null_object # rubocop:disable RSpec/VerifiedDoubles
  end

  let(:customizer) { nil }

  let(:config) do
    {
      name: 'environment name',
      config_files: config_files.keys.map(&:to_s)
    }
  end

  before do
    config_files.each do |file, content|
      allow(File).to receive(:read).with(file.to_s).and_return(content)
    end

    allow($stderr).to receive(:print)
  end

  describe 'loading configuration' do
    let(:config_files) do
      {
        one: 'one: 23',
        two: 'two: 42'
      }
    end

    before do
      described_class.load_configuration(config, store, customizer)
    end

    it 'should reinitialize the configatron store' do
      expect(store).to have_received(:unlock!)
      expect(store).to have_received(:reset!)
    end

    it 'should save the env to store' do
      expect(store).to have_received(:env=).with(config[:name])
    end

    it 'should load all config files' do
      config[:config_files].each do |file|
        expect(File).to have_received(:read).with(file)
      end
    end

    it "should add each config file's values to the store" do
      expect(store).to have_received(:configure_from_hash).with('one' => 23)
      expect(store).to have_received(:configure_from_hash).with('two' => 42)
    end

    it 'should lock the store' do
      expect(store).to have_received(:lock!)
    end

    describe 'customization' do
      let(:customizer) { instance_double(Proc).as_null_object }

      it 'should run the customizer' do
        expect(customizer).to have_received(:call).with(store)
      end
    end

    context 'config file with overriding values' do
      let(:config_files) do
        {
          one: 'foo: bar',
          two: 'foo: baz'
        }
      end

      let(:store) do
        Configatron::RootStore.new
      end

      it 'should merge config values' do
        expect(store.foo).to eq('baz')
      end
    end

    context 'env also defined in config file' do
      let(:config_files) do
        {
          with_env: 'env: foo'
        }
      end

      let(:store) do
        Configatron::RootStore.new
      end

      it 'should override env from config' do
        expect(store.env).to eq('foo')
      end
    end

    context 'empty config file' do
      let(:config_files) do
        {
          empty: ''
        }
      end

      it 'should configure with empty hash' do
        expect(store).to have_received(:configure_from_hash).with({})
      end
    end
  end

  describe 'config file with ERb' do
    context 'ERb success' do
      let(:config_files) do
        {
          with_erb: 'foo: <%= 40 + 2 %>'
        }
      end

      before do
        described_class.load_configuration(config, store)
      end

      it 'should evaluate ERb' do
        expect(store).to have_received(:configure_from_hash).with('foo' => 42)
      end
    end

    context 'ERb failure' do
      let(:config_files) do
        {
          with_erb: 'bogus: <%= 42 + "a" %>'
        }
      end

      it 'should report file name' do
        expect { described_class.load_configuration(config, store) }
          .to(raise_error { |ex| expect(ex.backtrace.join("\n")).to match(/with_erb/) })
      end
    end
  end
end
