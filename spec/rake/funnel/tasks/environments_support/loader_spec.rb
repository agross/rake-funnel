describe Rake::Funnel::Tasks::EnvironmentsSupport::Loader do
  describe 'loading configuration' do
    let(:config) {
      {
        name: 'environment name',
        config_files: config_files.keys.map(&:to_s)
      }
    }

    let(:config_files) {
      {
        one: 'one: 23',
        two: 'two: 42'
      }
    }

    let(:store) {
      double(Configatron::Store).as_null_object
    }

    before {
      config_files.each do |file, content|
        allow(File).to receive(:read).with(file.to_s).and_return(content)
      end

      allow(Rake).to receive(:rake_output_message)
    }

    before {
      described_class.load_configuration(config, store)
    }

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
      expect(store).to have_received(:configure_from_hash).with({ 'one' => 23 })
      expect(store).to have_received(:configure_from_hash).with({ 'two' => 42 })
    end

    it 'should lock the store' do
      expect(store).to have_received(:lock!)
    end

    context 'config file with overriding values' do
      let(:config_files) {
        {
          one: 'foo: bar',
          two: 'foo: baz'
        }
      }

      let(:store) {
        Configatron::RootStore.new
      }

      it 'should merge config values' do
        expect(store.foo).to eq('baz')
      end
    end

    context 'env also defined in config file' do
      let(:config_files) {
        {
          with_env: 'env: foo'
        }
      }

      let(:store) {
        Configatron::RootStore.new
      }

      it 'should override env from config' do
        expect(store.env).to eq('foo')
      end
    end

    context 'empty config file' do
      let(:config_files) {
        {
          empty: ''
        }
      }

      it 'should configure with empty hash' do
        expect(store).to have_received(:configure_from_hash).with({})
      end
    end

    context 'config file with ERb' do
      let(:config_files) {
        {
          with_erb: 'foo: <%= 40 + 2 %>'
        }
      }

      it 'should evaluate ERb' do
        expect(store).to have_received(:configure_from_hash).with({ 'foo' => 42 })
      end
    end
  end
end
