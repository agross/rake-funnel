require 'configatron'

describe Rake::Funnel::Tasks::Environments do
  include Rake::DSL

  before do
    Rake::Task.clear
  end

  let(:files) { [] }

  before do
    allow(Dir).to receive(:[]).and_return(files)
  end

  def disable_default_env_setup
    allow_any_instance_of(described_class).to receive(:default_environment_setup) # rubocop:disable RSpec/AnyInstance
  end

  describe 'defaults' do
    before do
      disable_default_env_setup
    end

    its(:store) { should == configatron }
    its(:base_dir) { should == 'config' }
    its(:default_env) { should be_nil }
    its(:default_config) { should == 'default' }
    its(:local_config) { should == 'local' }
    its(:customizer) { should be_nil }

    describe 'overriding defaults' do
      let(:store) { OpenStruct.new }

      subject do
        described_class.new do |t|
          t.store = store
          t.base_dir = 'custom base_dir'
          t.default_env = 'custom default_env'
          t.default_config = 'custom default_config'
          t.local_config = 'custom local_config'
          t.customizer = proc {}
        end
      end

      its(:store) { should == store }
      its(:base_dir) { should == subject.base_dir }
      its(:default_env) { should == subject.default_env }
      its(:default_config) { should == subject.default_config }
      its(:local_config) { should == subject.local_config }
      its(:customizer) { should be_instance_of(Proc) }
    end
  end

  describe 'definition' do
    before do
      disable_default_env_setup
    end

    before do
      allow_any_instance_of(described_class).to receive(:task) # rubocop:disable RSpec/AnyInstance
    end

    let(:files) do
      %w(config/default.yaml config/local.yaml config/dev.yaml config/production.yaml)
    end

    it 'should define a task for each config file' do
      expect(subject).to have_received(:task).with('dev')
      expect(subject).to have_received(:task).with('production')
    end

    it 'should omit environment for the default config file' do
      expect(subject).not_to have_received(:task).with('default')
    end

    it 'should omit environment for the local config file' do
      expect(subject).not_to have_received(:task).with('local')
    end
  end

  describe 'config files to load' do
    let(:optional) { nil }
    let(:files) do
      %w(config/dev.yaml)
    end

    before do
      allow(Rake::Funnel::Support::Environments::Loader).to receive(:load_configuration)
    end

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:exist?).with(optional).and_return(false)
    end

    subject! do
      described_class.new do |t|
        t.default_env = 'dev'
      end
    end

    before do
      Rake::Task['dev'].invoke
    end

    it 'should store configuration in configatron singleton' do
      expect(Rake::Funnel::Support::Environments::Loader).to \
        have_received(:load_configuration).with(anything, configatron, any_args)
    end

    context 'default and local config files exist' do
      let(:optional) { nil }

      it 'should load all files' do
        expect(Rake::Funnel::Support::Environments::Loader)
          .to have_received(:load_configuration)
          .with(hash_including(config_files: %w(config/default.yaml config/dev.yaml config/local.yaml)), any_args)
      end
    end

    context 'default config file does not exist' do
      let(:optional) { 'config/default.yaml' }

      it 'should load environment file and local file' do
        expect(Rake::Funnel::Support::Environments::Loader)
          .to have_received(:load_configuration)
          .with(hash_including(config_files: %w(config/dev.yaml config/local.yaml)), any_args)
      end
    end

    context 'local config file does not exist' do
      let(:optional) { 'config/local.yaml' }

      it 'should load default file and environment file' do
        expect(Rake::Funnel::Support::Environments::Loader).to \
          have_received(:load_configuration)
          .with(hash_including(config_files: %w(config/default.yaml config/dev.yaml)),
                any_args)
      end
    end
  end

  describe 'customization' do
    let(:customizer) { proc {} }
    let(:files) do
      %w(config/dev.yaml)
    end

    subject! do
      described_class.new do |t|
        t.customizer = customizer
      end
    end

    before do
      allow(Rake::Funnel::Support::Environments::Loader).to receive(:load_configuration)
    end

    before do
      Rake::Task['dev'].invoke
    end

    it 'should pass customizer to loader' do
      expect(Rake::Funnel::Support::Environments::Loader).to \
        have_received(:load_configuration).with(anything, anything, customizer)
    end
  end

  describe 'automatic environment setup' do
    let(:files) do
      %w(config/dev.yaml config/production.yaml)
    end

    before do
      Rake.application.top_level_tasks.clear
      Rake.application.top_level_tasks.push(*top_level_tasks)
    end

    context 'environment task defined in top-level Rake namespace' do
      subject! do
        described_class.new do |t|
          t.default_env = default_env
        end
      end

      context 'no default environment configured' do
        let(:default_env) { nil }
        let(:top_level_tasks) { [] }

        it 'should not add top-level environment tasks' do
          expect(Rake.application.top_level_tasks).to be_empty
        end
      end

      context 'default environment configured' do
        let(:default_env) { 'dev' }

        context 'no top-level environment task' do
          let(:top_level_tasks) { %w(foo) }

          it 'should prepend default top-level environment task' do
            expect(Rake.application.top_level_tasks).to eq([default_env] + top_level_tasks)
          end
        end

        context 'top-level environment task' do
          let(:top_level_tasks) { %w(foo production) }

          it 'should move top-level environment task to front' do
            expect(Rake.application.top_level_tasks).to eq(top_level_tasks.reverse)
          end
        end
      end
    end

    context 'environment task defined in Rake namespace' do
      subject! do
        namespace :foo do
          namespace :bar do
            described_class.new do |t|
              t.default_env = default_env
            end
          end
        end
      end

      context 'default environment configured' do
        let(:default_env) { 'dev' }

        context 'no top-level environment task' do
          let(:top_level_tasks) { %w(foo) }

          it 'should prepend default top-level environment task' do
            expect(Rake.application.top_level_tasks).to eq(["foo:bar:#{default_env}"] + top_level_tasks)
          end
        end

        context 'top-level environment task' do
          let(:top_level_tasks) { %w(foo foo:bar:production) }

          it 'should move top-level environment task to front' do
            expect(Rake.application.top_level_tasks).to eq(top_level_tasks.reverse)
          end
        end
      end
    end
  end
end
