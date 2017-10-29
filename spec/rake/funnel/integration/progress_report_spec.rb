describe Rake::Funnel::Integration::ProgressReport do
  include Rake::DSL

  let(:teamcity_running?) { false }

  before do
    allow($stdout).to receive(:puts)
    allow(Rake::Funnel::Integration::TeamCity).to receive(:running?).and_return(teamcity_running?)

    Rake::Task.clear
  end

  after do
    subject.disable!
  end

  describe 'defaults' do
    subject! do
      described_class.new
    end

    before do
      task :task

      Rake::Task[:task].invoke
    end

    context 'not on TeamCity' do
      it 'should write colored task name in square brackets' do
        expect($stdout).to have_received(:puts).with("\n[task]".bold.cyan)
      end
    end

    context 'on TeamCity' do
      let(:teamcity_running?) { true }

      it 'should not write task name since it would clutter the output' do
        expect($stdout).not_to have_received(:puts).with(/task/)
      end
    end
  end

  context 'when progess report was disabled' do
    subject do
      described_class.new
    end

    before do
      subject.disable!

      task :task

      Rake::Task[:task].invoke
    end

    it 'should not write' do
      expect($stdout).not_to have_received(:puts).with("\n[task]")
    end
  end

  describe 'custom event handlers' do
    let(:receiver) { double.as_null_object }

    subject! do
      described_class.new do |r|
        r.task_starting do |task, args|
          receiver.task_starting(task: task,
                                 args: args)
        end

        r.task_finished do |task, args, error|
          receiver.task_finished(task: task,
                                 args: args,
                                 error: error)
        end
      end
    end

    context 'when task succeeds' do
      before do
        task :task

        Rake::Task[:task].invoke
      end

      describe 'starting handler' do
        it 'should run' do
          expect(receiver).to have_received(:task_starting)
        end

        it 'should receive task' do
          expect(receiver).to have_received(:task_starting).with(hash_including(task: kind_of(Rake::Task)))
        end

        it 'should receive task arguments' do
          expect(receiver).to have_received(:task_starting).with(hash_including(args: kind_of(Rake::TaskArguments)))
        end
      end

      describe 'finished handler' do
        it 'should run' do
          expect(receiver).to have_received(:task_finished)
        end

        it 'should receive task' do
          expect(receiver).to have_received(:task_finished).with(hash_including(task: kind_of(Rake::Task)))
        end

        it 'should receive task arguments' do
          expect(receiver).to have_received(:task_finished).with(hash_including(args: kind_of(Rake::TaskArguments)))
        end

        it 'should not receive error' do
          expect(receiver).to have_received(:task_finished).with(hash_including(error: nil))
        end
      end
    end

    context 'when task fails' do
      class SpecificError < StandardError;  end

      let(:error) { SpecificError.new('task error') }

      before do
        task :task do
          raise error
        end

        begin
          Rake::Task[:task].invoke
        rescue SpecificError # rubocop:disable Lint/HandleExceptions
        end
      end

      describe 'finished handler' do
        it 'should receive error' do
          expect(receiver).to have_received(:task_finished).with(hash_including(error: error))
        end
      end
    end
  end
end
