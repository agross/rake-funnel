include Rake
include Rake::Funnel
include Rake::Funnel::Support
include Rake::Funnel::Tasks::MSDeploySupport

describe Rake::Funnel::Tasks::MSDeploy do
  before {
    CLEAN.clear
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :msdeploy }
    its(:msdeploy) { should == 'msdeploy' }
    its(:log_file) { should == 'msdeploy.log' }
    its(:args) { should == {} }

    it 'should add the log file to the files to be cleaned' do
      expect(CLEAN).to include(subject.log_file)
    end
  end

  describe 'overriding defaults' do
    context 'when task name is specified' do
      it 'should have a default log file equal to the task name' do
        expect(described_class.new(:foo).log_file).to eq('foo.log')
      end
    end

    context 'when task name and log file is specified' do
      subject! {
        described_class.new(:foo) do |t|
          t.log_file = 'bar.log'
        end
      }

      it 'should use custom log file' do
        expect(subject.log_file).to eq('bar.log')
      end

      it 'should add the log file to the files to be cleaned' do
        expect(CLEAN).to include(subject.log_file)
      end
    end
  end

  describe 'execution' do
    let(:msdeploy) { 'msdeploy' }
    let(:args) { {} }

    subject {
      described_class.new do |t|
        t.msdeploy = msdeploy
        t.args = args
      end
    }

    before {
      allow(subject).to receive(:shell)

      allow(RegistryPatch).to receive(:new).and_yield
    }

    describe 'argument mapping and invocation' do
      let(:mapper) { double(Mapper).as_null_object }

      before {
        allow(Mapper).to receive(:new).and_return(mapper)
      }

      before {
        Task[subject.name].invoke
      }

      it 'should use MSDeploy mapper' do
        expect(Mapper).to have_received(:new).with(:MSDeploy)
      end

      it 'should map arguments' do
        expect(mapper).to have_received(:map).with(args)
      end

      it 'should run with shell' do
        expect(subject).to have_received(:shell).with(/^msdeploy /,
            {
              log_file: 'msdeploy.log',
              error_lines: /^(error|[\w\.]*exception)/i
            })
      end
    end

    describe 'arg examples' do
      before {
        Task[subject.name].invoke
      }

      context 'skip actions' do
        let (:args) {
          {
            verb: :sync,
            source: {
              content_path: 'deploy'
            },
            dest: {
              computer_name: 'remote.example.com',
              username: 'bob',
              password: 'secret',
              auto: true
            },
            skip: [
              { directory: 'logs' },
              {
                object_name: 'filePath',
                skip_action: 'Delete',
                absolute_path: 'App_Offline\.htm$'
              }
            ],
            use_checksum: nil,
            allow_untrusted: nil
          }
        }

        it 'should succeed' do
          args = %w(
            msdeploy
            -verb:sync
            -source:contentPath=deploy
            -dest:computerName=remote.example.com,username=bob,password=secret,auto=true
            -skip:directory=logs
            -skip:objectName=filePath,skipAction=Delete,absolutePath=App_Offline\.htm$
            -useChecksum
            -allowUntrusted
            )

          expect(subject).to have_received(:shell).with(args.join(' '), be_an_instance_of(Hash))
        end
      end

      context 'runCommand' do
        let(:args) {
          {
            verb: :sync,
            source: {
              run_command: 'cd "C:\Program Files"',
              wait_interval: 1
            },
            dest: {
              computer_name: 'remote.example.com',
              username: 'bob',
              password: 'secret',
              auto: true
            }
          }
        }

        it 'should succeed' do
          args = %w(
            msdeploy
            -verb:sync
            -source:runCommand="cd ""C:\Program Files""",waitInterval=1
            -dest:computerName=remote.example.com,username=bob,password=secret,auto=true
            )

          expect(subject).to have_received(:shell).with(args.join(' '), be_an_instance_of(Hash))
        end
      end

      context 'preSync runCommand' do
        let(:args) {
          {
            verb: :sync,
            pre_sync: {
              run_command: 'cd "C:\Program Files"',
              dont_use_command_exe: :true
            },
            source: {
              content_path: 'deploy'
            },
            dest: {
              computer_name: 'remote.example.com',
              username: 'bob',
              password: 'secret'
            }
          }
        }

        it 'should succeed' do
          args = %w(
            msdeploy
            -verb:sync
            -preSync:runCommand="cd ""C:\Program Files""",dontUseCommandExe=true
            -source:contentPath=deploy
            -dest:computerName=remote.example.com,username=bob,password=secret
            )

          expect(subject).to have_received(:shell).with(args.join(' '), be_an_instance_of(Hash))
        end
      end
    end

    describe "MSDeploy's idiocy" do
      before {
        Task[subject.name].invoke
      }

      describe 'version registry value that is required to exist' do
        it 'should patch the registry' do
          expect(RegistryPatch).to have_received(:new)
        end
      end

      describe 'command line parser that requires quotes inside but not outside parameters' do
        let(:msdeploy) { 'path to/msdeploy' }

        let(:args) {
          {
            'simple key' => 'simple value',
            hash: {
              'hash key 1' => 'hash value 1',
              'hash key 2' => 'hash value 2'
            },
            array: ['array value 1', 'array value 2'],
            'some flag' => nil
          }
        }

        it 'should quote the string' do
          args = '"path to/msdeploy" -"simple key":"simple value" -hash:"hash key 1"="hash value 1","hash key 2"="hash value 2" -array:"array value 1" -array:"array value 2" -"some flag"'
          args = %w(
            "path to/msdeploy"
            -"simple key":"simple value"
            -hash:"hash key 1"="hash value 1","hash key 2"="hash value 2"
            -array:"array value 1"
            -array:"array value 2"
            -"some flag"
            ).join(' ')

          expect(subject).to have_received(:shell).with(args, be_an_instance_of(Hash))
        end
      end
    end
  end
end
