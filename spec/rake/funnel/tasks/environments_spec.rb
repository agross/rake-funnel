include Rake
include Rake::Funnel::Support
include Rake::Funnel::Tasks

describe Rake::Funnel::Tasks::Environments do
  include Rake::DSL

  before {
    Task.clear
  }

  before {
    module Kernel
      def configatron
        OpenStruct.new(name: 'fake configatron singleton')
      end
    end
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

    its(:base_dir) { should == 'config' }
    its(:default_env) { should be_nil }
    its(:default_config) { should == 'default' }
    its(:local_config) { should == 'local' }
    its(:customizer) { should be_nil }

    describe 'overriding defaults' do
      subject {
        described_class.new do |t|
          t.base_dir = 'custom base_dir'
          t.default_env = 'custom default_env'
          t.default_config = 'custom default_config'
          t.local_config = 'custom local_config'
          t.customizer = Proc.new {}
        end
      }

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
    let(:files) {
      %w(config/dev.yaml)
    }

    before {
      allow(EnvironmentsSupport::Loader).to receive(:load_configuration)
    }

    before {
      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:exists?).with(optional).and_return(false)
    }

    subject {
      described_class.new do |t|
        t.default_env = 'dev'
      end
    }

    before {
      expect(subject).to be
    }

    context 'default and local config files exist' do
      let(:optional) { nil }

      it 'should load all files' do
        expect(EnvironmentsSupport::Loader)
          .to have_received(:load_configuration).with(hash_including({ config_files: %w(config/default.yaml config/dev.yaml config/local.yaml) }), any_args)
      end
    end

    context 'default config file does not exist' do
      let(:optional) { 'config/default.yaml' }

      it 'should load environment file and local file' do
        expect(EnvironmentsSupport::Loader)
          .to have_received(:load_configuration).with(hash_including({ config_files: %w(config/dev.yaml config/local.yaml) }), any_args)
      end
    end

    context 'local config file does not exist' do
      let(:optional) { 'config/local.yaml' }

      it 'should load default file and environment file' do
        expect(EnvironmentsSupport::Loader)
          .to have_received(:load_configuration).with(hash_including({ config_files: %w(config/default.yaml config/dev.yaml) }), any_args)
      end
    end
  end

  describe 'store' do
    let(:files) {
      %w(config/dev.yaml)
    }

    before {
      allow(EnvironmentsSupport::Loader).to receive(:load_configuration)
    }

    before {
      expect(subject).to be
      Task['dev'].invoke
    }

    it 'should store configuration in configatron singleton' do
      expect(EnvironmentsSupport::Loader).to have_received(:load_configuration).with(anything, configatron, any_args)
    end
  end

  describe 'customization' do
    let(:customizer) { Proc.new {} }
    let(:files) {
      %w(config/dev.yaml)
    }

    subject {
      described_class.new do |t|
        t.customizer = customizer
      end
    }

    before {
      allow(EnvironmentsSupport::Loader).to receive(:load_configuration)
    }

    before {
      expect(subject).to be
      Task['dev'].invoke
    }

    it 'should pass customizer to loader' do
      expect(EnvironmentsSupport::Loader).to have_received(:load_configuration).with(anything, anything, customizer)
    end
  end

  describe 'automatic environment setup' do
    let(:files) {
      %w(config/dev.yaml config/production.yaml)
    }

    before {
      allow(EnvironmentsSupport::Loader).to receive(:load_configuration)
    }

    context 'no default environment configured' do
      before {
        expect(subject).to be
      }

      it 'should not invoke environment tasks' do
        expect(EnvironmentsSupport::Loader).not_to have_received(:load_configuration)
      end
    end

    context 'default environment configured' do
      subject {
        described_class.new do |t|
          t.default_env = 'dev'
        end
      }

      before {
        allow(Rake.application).to receive(:top_level_tasks).and_return(user_defined_task)
      }

      before {
        expect(subject).to be
      }

      context 'no user-defined environment' do
        let(:user_defined_task) { %w(foo) }

        it 'should invoke default environment task' do
          expect(EnvironmentsSupport::Loader)
            .to have_received(:load_configuration).with(hash_including({ name: 'dev' }), any_args)
        end

        it 'should not invoke other environment tasks' do
          expect(EnvironmentsSupport::Loader)
            .not_to have_received(:load_configuration).with(hash_including({ name: 'production' }), any_args)
        end
      end

      context 'user-defined environment' do
        let(:user_defined_task) { %w(foo production) }

        it 'should invoke user-defined environment task' do
          expect(EnvironmentsSupport::Loader)
            .to have_received(:load_configuration).with(hash_including({ name: 'production' }), any_args)
        end

        it 'should not invoke other environment tasks' do
          expect(EnvironmentsSupport::Loader)
            .not_to have_received(:load_configuration).with(hash_including({ name: 'dev' }), any_args)
        end
      end

      context 'environment task defined in Rake namespace' do
        subject {
          namespace :foo do
            namespace :bar do
              described_class.new do |t|
                t.default_env = 'dev'
              end
            end
          end
        }

        context 'default environment configured' do
          before {
            expect(subject).to be
          }

          context 'no user-defined environment' do
            let(:user_defined_task) { %w(foo) }

            it 'should invoke default environment task' do
              expect(EnvironmentsSupport::Loader)
                .to have_received(:load_configuration).with(hash_including({ name: 'dev' }), any_args)
            end

            it 'should not invoke other environment tasks' do
              expect(EnvironmentsSupport::Loader)
                .not_to have_received(:load_configuration).with(hash_including({ name: 'production' }), any_args)
            end
          end

          context 'user-defined environment' do
            let(:user_defined_task) { %w(foo foo:bar:production) }

            it 'should invoke user-defined environment task' do
              expect(EnvironmentsSupport::Loader)
                .to have_received(:load_configuration).with(hash_including({ name: 'production' }), any_args)
            end

            it 'should not invoke other environment tasks' do
              expect(EnvironmentsSupport::Loader)
                .not_to have_received(:load_configuration).with(hash_including({ name: 'dev' }), any_args)
            end
          end
        end
      end
    end
  end
end
