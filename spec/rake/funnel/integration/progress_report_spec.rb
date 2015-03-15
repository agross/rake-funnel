include Rake
include Rake::Funnel::Integration

describe Rake::Funnel::Integration::ProgressReport do
  include DSL

  let(:teamcity_running?) { false }

  before {
    allow($stdout).to receive(:puts)
    allow(TeamCity).to receive(:running?).and_return(teamcity_running?)

    Task.clear
  }

  after {
    subject.disable!
  }

  describe 'defaults' do
    subject! {
      described_class.new
    }

    before {
      task :task

      Task[:task].invoke
    }

    context 'not on TeamCity' do
      it 'should write task name in square brackets' do
        expect($stdout).to have_received(:puts).with("\n[task]")
      end
    end

    context 'on TeamCity' do
      let(:teamcity_running?) { true }

      it 'should not write task name in square brackets since it would clutter the output' do
        expect($stdout).to_not have_received(:puts).with("\n[task]")
      end
    end
  end

  context 'when progess report was disabled' do
    subject! {
      described_class.new
    }

    before {
      subject.disable!

      task :task

      Task[:task].invoke
    }

    it 'should not write' do
      expect($stdout).to_not have_received(:puts).with("\n[task]")
    end
  end

  describe 'custom event handlers' do
    let(:receiver) { double.as_null_object }

    subject! {
      described_class.new do |r|
        r.task_starting do |task, args|
          receiver.starting({
            task: task,
            args: args
          })
        end

        r.task_finished do |task, args, error|
          receiver.finished({
            task: task,
            args: args,
            error: error
          })
        end
      end
    }

    context 'when task succeeds' do
      before {
        task :task

        Task[:task].invoke
      }

      describe 'starting handler' do
        it 'should run' do
          expect(receiver).to have_received(:starting)
        end

        it 'should receive task' do
          expect(receiver).to have_received(:starting).with(hash_including({ task: kind_of(Task) }))
        end

        it 'should receive task arguments' do
          expect(receiver).to have_received(:starting).with(hash_including({ args: kind_of(TaskArguments) }))
        end
      end

      describe 'finished handler' do
        it 'should run' do
          expect(receiver).to have_received(:finished)
        end

        it 'should receive task' do
          expect(receiver).to have_received(:finished).with(hash_including({ task: kind_of(Task) }))
        end

        it 'should receive task arguments' do
          expect(receiver).to have_received(:finished).with(hash_including({ args: kind_of(TaskArguments) }))
        end

        it 'should not receive error' do
          expect(receiver).to have_received(:finished).with(hash_including({ error: nil }))
        end
      end
    end

    context 'when task fails' do
      class SpecificError < StandardError;  end

      let(:error) { SpecificError.new('task error') }

      before {
        task :task do
          raise error
        end

        begin
          Task[:task].invoke
        rescue SpecificError
        end
      }

      describe 'finished handler' do
        it 'should receive error' do
          expect(receiver).to have_received(:finished).with(hash_including({ error: error }))
        end
      end
    end
  end
end
