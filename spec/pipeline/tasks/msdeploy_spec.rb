require 'rake'
require 'rake/clean'
require 'open3'
require 'ostruct'
require 'pipeline'

include Pipeline::Tasks

describe MSDeploy do

  before {
    CLEAN.clear
    Rake::Task.clear
    File.stub(:open)
    subject.stub(:mkdir_p)
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
    before {
      $stdout.stub(:puts)
      $stderr.stub(:puts)
    }

    describe 'success' do
      before { Open3.stub(:popen2e) }

      it 'should create the directory for the log file' do
        subject.log_file = 'somewhere/else/msdeploy.log'

        Rake::Task[:msdeploy].invoke

        expect(subject).to have_received(:mkdir_p).with('somewhere/else')
      end

      it 'should run' do
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

        expect(Open3).to have_received(:popen2e).with(args.join(' '))
      end
    end

    context 'failure' do
      describe 'error detection' do
        it 'should fail when process status reports failure' do
          error_exit = OpenStruct.new(value: OpenStruct.new(success?: false))
          Open3.stub(:popen2e).and_yield(nil, StringIO.new('success output'), error_exit)

          expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError)
        end

        it 'should fail when an error is logged' do
          success_exit = OpenStruct.new(value: OpenStruct.new(success?: true))
          Open3.stub(:popen2e).and_yield(nil, StringIO.new('Error: foo'), success_exit)

          expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError)
        end

        it 'should fail when an exception is logged' do
          success_exit = OpenStruct.new(value: OpenStruct.new(success?: true))
          Open3.stub(:popen2e).and_yield(nil, StringIO.new('Exception: foo'), success_exit)

          expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError)
        end
      end

      describe 'error reporting' do
        before { subject.stub(:run_with_redirected_output).and_yield(false, 127, 'command', 'errors') }

        it "should fail when MSDeploy's exit code is not 0" do
          expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError)
        end

        it 'should report the exit code' do
          expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError, /exit code 127/)
        end

        it 'should report the command that was run' do
          expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError, /command/)
        end

        it 'should report logged lines' do
          expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError, /errors/)
        end
      end
    end

    describe "MSDeploy's idiotic command line parser that requires quotes inside but not outside parameters" do
      before { Open3.stub(:popen2e) }

      it 'should escape the string before calling sh' do
        subject.msdeploy = 'path to/msdeploy'
        subject.log_file = 'path to/msdeploy.log'
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

        expect(Open3).to have_received(:popen2e).with(args)
      end
    end
  end
end
