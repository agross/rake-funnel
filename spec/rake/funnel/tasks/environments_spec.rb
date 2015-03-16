require 'configatron'

include Rake
include Rake::Funnel::Support::Environments
include Rake::Funnel::Tasks

describe Rake::Funnel::Tasks::Environments do
  include Rake::DSL

  before {
    Task.clear
  }

  let(:files) { [] }

  before {
    allow(Dir).to receive(:[]).and_return(files)
  }

  def disable_default_env_setup
    allow_any_instance_of(described_class).to receive(:default_environment_setup)
  end

  describe 'defaults' do
    before {
      disable_default_env_setup
    }

    its(:store) { should == configatron }
    its(:base_dir) { should == 'config' }
    its(:default_env) { should be_nil }
    its(:default_config) { should == 'default' }
    its(:local_config) { should == 'local' }
    its(:customizer) { should be_nil }

    describe 'overriding defaults' do
      let(:store) { OpenStruct.new }

      subject {
        described_class.new do |t|
          t.store = store
          t.base_dir = 'custom base_dir'
          t.default_env = 'custom default_env'
          t.default_config = 'custom default_config'
          t.local_config = 'custom local_config'
          t.customizer = proc {}
        end
      }

      its(:store) { should == store }
      its(:base_dir) { should == subject.base_dir }
      its(:default_env) { should == subject.default_env }
      its(:default_config) { should == subject.default_config }
      its(:local_config) { should == subject.local_config }
      its(:customizer) { should be_instance_of(Proc) }
    end
  end

  describe 'definition' do
    before {
      disable_default_env_setup
    }

    before {
      allow_any_instance_of(described_class).to receive(:task)
    }

    let(:files) {
      %w(config/default.yaml config/local.yaml config/dev.yaml config/production.yaml)
    }

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
    let(:files) {
      %w(config/dev.yaml)
    }

    before {
      allow(Loader).to receive(:load_configuration)
    }

    before {
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:exist?).with(optional).and_return(false)
    }

    subject! {
      described_class.new do |t|
        t.default_env = 'dev'
      end
    }

    before {
      Task['dev'].invoke
    }

    it 'should store configuration in configatron singleton' do
      expect(Loader).to have_received(:load_configuration).with(anything, configatron, any_args)
    end

    context 'default and local config files exist' do
      let(:optional) { nil }

      it 'should load all files' do
        expect(Loader)
          .to have_received(:load_configuration)
              .with(hash_including({ config_files: %w(config/default.yaml config/dev.yaml config/local.yaml) }), any_args)
      end
    end

    context 'default config file does not exist' do
      let(:optional) { 'config/default.yaml' }

      it 'should load environment file and local file' do
        expect(Loader)
          .to have_received(:load_configuration)
              .with(hash_including({ config_files: %w(config/dev.yaml config/local.yaml) }), any_args)
      end
    end

    context 'local config file does not exist' do
      let(:optional) { 'config/local.yaml' }

      it 'should load default file and environment file' do
        expect(Loader)
          .to have_received(:load_configuration).with(hash_including({ config_files: %w(config/default.yaml config/dev.yaml) }), any_args)
      end
    end
  end

  describe 'customization' do
    let(:customizer) { proc {} }
    let(:files) {
      %w(config/dev.yaml)
    }

    subject! {
      described_class.new do |t|
        t.customizer = customizer
      end
    }

    before {
      allow(Loader).to receive(:load_configuration)
    }

    before {
      Task['dev'].invoke
    }

    it 'should pass customizer to loader' do
      expect(Loader).to have_received(:load_configuration).with(anything, anything, customizer)
    end
  end

  describe 'automatic environment setup' do
    let(:files) {
      %w(config/dev.yaml config/production.yaml)
    }

    before {
      Rake.application.top_level_tasks.clear
      Rake.application.top_level_tasks.push(*top_level_tasks)
    }

    context 'environment task defined in top-level Rake namespace' do
      subject! {
        described_class.new do |t|
          t.default_env = default_env
        end
      }

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
      subject! {
        namespace :foo do
          namespace :bar do
            described_class.new do |t|
              t.default_env = default_env
            end
          end
        end
      }

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
