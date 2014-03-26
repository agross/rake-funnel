require 'rake'
require 'rake/clean'
require 'pipeline'

include Pipeline::Tasks

describe MSDeploy do
  before {
    CLEAN.clear
    Rake::Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :msdeploy }
    its(:msdeploy) { should == 'msdeploy' }
    its(:log_file) { should == 'msdeploy.log' }
    its(:args) { should == {} }

    it 'should add the log file to the files to be cleaned' do
      CLEAN.should include(subject.log_file)
    end
  end

  describe 'overriding defaults' do
    context 'when task name is specified' do
      it 'should have a default log file equal to the task name' do
        MSDeploy.new(:foo).log_file.should == 'foo.log'
      end
    end

    context 'when task name and log file is specified' do
      subject! {
        MSDeploy.new(:foo) do |t|
          t.log_file = 'bar.log'
        end
      }

      it 'should use custom log file' do
        subject.log_file.should == 'bar.log'
      end

      it 'should add the log file to the files to be cleaned' do
        CLEAN.should include(subject.log_file)
      end
    end
  end

  describe 'execution' do
    before { subject.stub(:shell) }

    it 'should run with shell' do
      subject.args = {
        verb: :sync,
        source: {
          content_path: 'deploy'
          },
        dest: {
          computer_name: 'remote.example.com',
          username: 'bob',
          password: 'secret'
          },
        skip: [
          { directory: 'logs'},
          {
            object_name: 'filePath',
            skip_action: 'Delete',
            absolute_path: 'App_Offline\.htm$'
          }
        ],
        usechecksum: true,
        allow_untrusted: true
      }

      Rake::Task[:msdeploy].invoke

      args = %w(
        msdeploy
        -verb:sync
        -source:contentPath=deploy
        -dest:computerName=remote.example.com,username=bob,password=secret
        -skip:directory=logs
        -skip:objectName=filePath,skipAction=Delete,absolutePath=App_Offline\.htm$
        -usechecksum
        -allowUntrusted
        )

      expect(subject).to have_received(:shell)
        .with(args.join(' '),
          { :log_file => 'msdeploy.log',
            :error_lines => /^(error|[\w\.]*exception)/i })
    end

    describe "MSDeploy's idiotic command line parser that requires quotes inside but not outside parameters" do
      it 'should escape the string before calling shell' do
        subject.msdeploy = 'path to/msdeploy'
        subject.args = {
          'simple key' => 'simple value',
          hash: {
            'hash key 1' => 'hash value 1',
            'hash key 2' => 'hash value 2'
            },
          array: ['array value 1', 'array value 2'],
          'some flag' => true
        }

        Rake::Task[:msdeploy].invoke

        args = '"path to/msdeploy" -"simple key":"simple value" -hash:"hash key 1"="hash value 1","hash key 2"="hash value 2" -array:"array value 1" -array:"array value 2" -"some flag"'

        expect(subject).to have_received(:shell).with(args, be_an_instance_of(Hash))
      end
    end
  end
end
