require 'pipeline'
require 'open3'
require 'smart_colored/extend'

describe Pipeline::Extensions::Shell do
  before {
    Open3.stub(:popen2e).and_yield(nil, stdout_and_stderr, exit)

    $stdout.stub(:puts)
    $stderr.stub(:puts)
    Rake.stub(:rake_output_message)
  }

  let(:exit) { OpenStruct.new(value: OpenStruct.new( success?: true, exitstatus: 0)) }

  let(:stdout_and_stderr) { StringIO.new("output 1\noutput 2\n") }

  subject { Object.new.extend(Pipeline::Extensions::Shell) }

  after { stdout_and_stderr.close }

  describe 'command' do
    it 'should accept simple commands' do
      arg = 'simple'

      subject.shell(arg)

      expect(Open3).to have_received(:popen2e).with('simple')
    end

    it 'should accept commands with arguments as array' do
      args = %w(1 2)

      subject.shell(args)

      expect(Open3).to have_received(:popen2e).with(args)
    end

    it 'should accept commands with arguments' do
      subject.shell('1', 2)

      expect(Open3).to have_received(:popen2e).with('1', 2)
    end

    it 'should echo the command' do
      arg = '1', 2

      subject.shell(arg)

      expect(Rake).to have_received(:rake_output_message).with(arg.join(' '))
    end
  end

  it 'should return nil' do
    subject.shell('foo').should be_nil
  end

  describe 'output redirection' do
    before { subject.shell('foo') }

    it 'should redirect command output to stdout' do
      expect($stdout).to have_received(:puts).with(/output 1/)
      expect($stdout).to have_received(:puts).with(/output 2/)
    end

    it 'should colorize lines' do
      expect($stdout).to have_received(:puts).with('output 1'.green)
    end
  end

  describe 'log file' do
    before {
      subject.stub(:mkdir_p)
      File.stub(:open)
    }

    let(:log_file) { nil }

    before { subject.shell('foo', log_file: log_file) }

    context 'no log file' do
      it 'should not create path to log file' do
        expect(subject).to_not have_received(:mkdir_p)
      end

      it 'should not write log file' do
        expect(subject).to_not have_received(:mkdir_p)
        expect(File).to_not have_received(:open)
      end
    end

    context 'with log file' do
      let(:log_file) { 'tmp/log.txt' }

      it 'should create path to log file' do
        expect(subject).to have_received(:mkdir_p).with(File.dirname(log_file))
      end

      it 'should append to log file' do
        expect(File).to have_received(:open).with(log_file, 'a').at_least(:once)
      end
    end
  end

  describe 'error detection' do
    let(:error_lines) { /error/ }

    before {
      begin
        subject.shell('foo', error_lines: error_lines)
      rescue Pipeline::ExecutionError
      end
    }

    context 'no lines indicating errors' do
      it 'should not log to stderr' do
        expect($stderr).to_not have_received(:puts)
      end
    end

    context 'lines indicating errors' do
      let(:stdout_and_stderr) { StringIO.new("output 1\nerror\noutput 2\n") }

      it 'should log to stdout before error' do
        expect($stdout).to have_received(:puts).with(/output 1/)
      end

      it 'should log to stderr on error' do
        expect($stderr).to have_received(:puts).with(/error/)
      end

      it 'should not log to stdout on error' do
        expect($stdout).to_not have_received(:puts).with(/error/)
      end

      it 'should colorize error lines' do
        expect($stderr).to have_received(:puts).with('error'.bold.red)
      end

      it 'should log to stdout after error' do
        expect($stdout).to have_received(:puts).with(/output 2/)
      end
    end
  end

  describe 'callback block' do
    it 'should yield' do
      expect { |b| subject.shell('foo', &b) }.to yield_control
    end

    it 'should yield the success status' do
      expect { |b| subject.shell('foo', &b) }.to yield_with_args(true, be, be, be)
    end

    it 'should yield the command' do
      expect { |b| subject.shell('foo', &b) }.to yield_with_args(be, 'foo', be, be)
    end

    it 'should yield the exit code' do
      expect { |b| subject.shell('foo', &b) }.to yield_with_args(be, be, 0, be)
    end

    it 'should yield the log' do
      expect { |b| subject.shell('foo', &b) }.to yield_with_args(be, be, be, /output/)
    end
  end

  describe 'failure' do
    context 'error lines logged' do
      context 'without block' do
        it 'should fail' do
          expect{ subject.shell('foo', error_lines: /.*/) }.to raise_error(Pipeline::ExecutionError)
        end
      end

      context 'with block' do
        it 'should not fail' do
          expect{ subject.shell('foo', error_lines: /.*/) {} }.not_to raise_error
        end

        it 'should yield the error' do
          expect { |b| subject.shell('foo', error_lines: /.*/, &b) }.to yield_with_args(false, 'foo', 0, /output/)
        end
      end
    end

    context 'error exit' do
      let(:exit) { OpenStruct.new(value: OpenStruct.new(success?: false, exitstatus: 1)) }

      context 'without block' do
        it 'should fail' do
          expect{ subject.shell('foo') }.to raise_error(Pipeline::ExecutionError)
        end

        it 'should report the exit code' do
          expect{ subject.shell('foo') }.to raise_error { |e| e.exit_code.should == exit.value.exitstatus }
        end

        it 'should report the command that was run' do
          expect{ subject.shell('foo') }.to raise_error { |e| e.command.should == 'foo' }
        end

        it 'should report logged lines' do
          expect{ subject.shell('foo') }.to raise_error { |e| e.output.should == stdout_and_stderr.string }
        end
      end

      context 'with block' do
        it 'should not fail' do
          expect{ subject.shell('foo') {} }.not_to raise_error
        end

        it 'should yield the error' do
          expect { |b| subject.shell('foo', error_lines: /.*/, &b) }.to yield_with_args(false, 'foo', 1, /output/)
        end
      end
    end
  end
end
