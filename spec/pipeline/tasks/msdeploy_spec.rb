require 'rake'
require 'rake/clean'
require 'pipeline'
require 'open3'

describe Pipeline::Tasks::MSDeploy do

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
        Pipeline::Tasks::MSDeploy.new(:foo).log_file.should == 'foo.log'
      end
    end

    context 'when task name and log file is specified' do
      subject! {
        Pipeline::Tasks::MSDeploy.new(:foo) do |t|
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

  describe 'argument conversion' do
    it 'should convert verb => <true boolean> to -verb' do
      subject.args = { verb: true }
      subject.transform_args.should =~ ['-verb']
    end

    it 'should convert verb => <truthy arg> to -verb:value' do
      subject.args = { verb: 1 }
      subject.transform_args.should =~ ['-verb:1']
    end

    it 'should omit verb => <false boolean>' do
      subject.args = { verb: false }
      subject.transform_args.should_not include('-verb')
    end

    it 'should omit verb => <falsy arg>' do
      subject.args = { verb: nil }
      subject.transform_args.should_not include('-verb')
    end

    it 'should convert verb => <symbol> to -verb:symbol-as-string' do
      subject.args = { verb: :foo }
      subject.transform_args.should =~ ['-verb:foo']
    end

    it 'should convert verb => <string> args to -verb:string value' do
      subject.args = { verb: 'string' }
      subject.transform_args.should =~ ['-verb:string']
    end

    it 'should convert verb => <enumerable> to -verb:value1,value2,value3' do
      subject.args = { verb: [1, 'a', :b, :some_value, true, false] }
      subject.transform_args.should =~ ['-verb:1,a,b,someValue,true,false']
    end

    it 'should convert verb => <hash> to -verb:key1=value1,key2=value2' do
      subject.args = { verb: { :key1 => 'value1', :second_key => :second_value } }
      subject.transform_args.should =~ ['-verb:key1=value1,secondKey=secondValue']
    end

    it 'should convert snake case symbols to camel case' do
      subject.args = { some_verb: :some_value }
      subject.transform_args.should =~ ['-someVerb:someValue']
    end

    it 'should enclose values with whitespace in "' do
      subject.args = { verb: 'some value' }
      subject.transform_args.should =~ ['-verb:"some value"']
    end

    it 'should enclose enumerable values with whitespace in "' do
      subject.args = { verb: [1, 'some value'] }
      subject.transform_args.should =~ ['-verb:1,"some value"']
    end

    it 'should enclose hash values with whitespace in "' do
      subject.args = { verb: { :key => 'some value' } }
      subject.transform_args.should =~ ['-verb:key="some value"']
    end
  end

  describe 'execution' do
    before {
      Open3.stub(:popen2e)
      subject.stub(:mkdir_p)
    }

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
        usechecksum: true,
        allow_untrusted: true
      }

      Rake::Task[:msdeploy].invoke

      args = %w(
        msdeploy
        -verb:sync
        -source:contentPath=deploy
        -dest:computerName=remote.example.com,username=bob,password=secret
        -usechecksum
        -allowUntrusted
        )

      expect(Open3).to have_received(:popen2e).with(args.join(' '))
    end

    context 'when MSDeploy execution fails' do
      before { subject.stub(:run_with_redirected_output).and_yield(false, 127, "errors") }

      it "should fail when MSDeploy's exit code is not 0" do
        expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError)
      end

      it "should report the exit code" do
        expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError, /exit code 127/)
      end

      it "should report logged lines" do
        expect { Rake::Task[:msdeploy].invoke }.to raise_error(Pipeline::ExecutionError, /errors/)
      end

      # No idea how to test this...
      # it 'should fail when an error is logged'
    end

    describe "MSDeploy's idiotic command line parser that requires quotes inside but not outside parameters" do
      context 'when values contain spaces' do
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

          args = '"path to/msdeploy" -"simple key":"simple value" -hash:"hash key 1"="hash value 1","hash key 2"="hash value 2" -array:"array value 1","array value 2" -"some flag"'

          expect(Open3).to have_received(:popen2e).with(args)
        end
      end
    end
  end
end
