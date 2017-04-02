# rubocop:disable RSpec/FilePath

include Rake
include Rake::Funnel
include Rake::Funnel::Support
include Rake::Funnel::Support::MSDeploy

describe Rake::Funnel::Tasks::MSDeploy do
  before do
    Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :msdeploy }
    its(:msdeploy) { should == 'msdeploy' }
    its(:log_file) { should == 'msdeploy.log' }
    its(:args) { should == {} }

    context 'when task name is specified' do
      it 'should have a default log file equal to the task name' do
        expect(described_class.new(:foo).log_file).to eq('foo.log')
      end
    end
  end

  describe 'execution' do
    let(:msdeploy) { 'msdeploy' }
    let(:args) { {} }

    subject do
      described_class.new do |t|
        t.msdeploy = msdeploy
        t.args = args
      end
    end

    before do
      allow(subject).to receive(:shell)

      allow(RegistryPatch).to receive(:new).and_yield
    end

    describe 'argument mapping and invocation' do
      let(:mapper) { instance_double(Mapper).as_null_object }

      before do
        allow(Mapper).to receive(:new).and_return(mapper)
      end

      before do
        Task[subject.name].invoke
      end

      it 'should use MSDeploy mapper' do
        expect(Mapper).to have_received(:new).with(:MSDeploy)
      end

      it 'should map arguments' do
        expect(mapper).to have_received(:map).with(args)
      end

      it 'should run with shell' do
        expect(subject).to have_received(:shell).with(/^msdeploy /,
                                                      log_file: 'msdeploy.log',
                                                      error_lines: /^(error|[\w\.]*exception)/i)
      end
    end

    describe 'arg examples' do
      before do
        Task[subject.name].invoke
      end

      context 'skip actions' do
        let(:args) do
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
        end

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
        let(:args) do
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
        end

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
        let(:args) do
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
        end

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
      before do
        Task[subject.name].invoke
      end

      describe 'version registry value that is required to exist' do
        it 'should patch the registry' do
          expect(RegistryPatch).to have_received(:new)
        end
      end

      describe 'command line parser that requires quotes inside but not outside parameters' do
        let(:msdeploy) { 'path to/msdeploy' }

        let(:args) do
          {
            'simple key' => 'simple value',
            hash: {
              'hash key 1' => 'hash value 1',
              'hash key 2' => 'hash value 2'
            },
            array: ['array value 1', 'array value 2'],
            'some flag' => nil
          }
        end

        it 'should quote the string' do
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
