require 'rake'
require 'pipeline'

include Pipeline::Integration

describe ProgressReport do

  include Rake::DSL

  let!(:report) { described_class.new }

  before { $stdout.stub(:puts) }

  before { Rake::Task.clear }

  after { report.reset! }

  describe 'running a rake task' do
    describe 'default actions' do
      let(:teamcity_running?) { false }

      before {
        TeamCity.stub(:running?).and_return(teamcity_running?)
        TeamCity.stub(:block_opened)
        TeamCity.stub(:block_closed)
        TeamCity.stub(:progress_start)
        TeamCity.stub(:progress_finished)
      }

      before {
        task :task

        Rake::Task[:task].invoke
      }

      it 'should write block start' do
        expect(TeamCity).to have_received(:block_opened).with(name: 'task')
      end

      it 'should write progress start' do
        expect(TeamCity).to have_received(:progress_start).with('task')
      end

      it 'should write block end' do
        expect(TeamCity).to have_received(:block_closed).with(name: 'task')
      end

      context 'not on TeamCity' do
        let(:teamcity_running?) { false }

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

    context 'when task fails' do
      before {
        TeamCity.stub(:running)
        TeamCity.stub(:block_closed)
      }

      before {
        task :task do
          raise Pipeline::ExecutionError.new('task error')
        end

        begin
          Rake::Task[:task].invoke
        rescue Pipeline::ExecutionError => e
          @raised_error = e
        end
      }

      it 'should write block end' do
        expect(TeamCity).to have_received(:block_closed).with(name: 'task')
      end

      it 'should keep the error' do
        @raised_error.should be_a_kind_of(Pipeline::ExecutionError)
      end
    end

    context 'when report was reset' do
      before {
        TeamCity.stub(:block_opened)
      }

      before {
        report.reset!

        task :task

        Rake::Task[:task].invoke
      }

      it 'should not write' do
        expect(TeamCity).to_not have_received(:block_opened)
      end
    end
  end

  describe 'custom event handlers' do
    let(:receiver) { double.as_null_object }

    let!(:report) {
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

        Rake::Task[:task].invoke
      }

      describe 'starting handler' do
        it 'should run' do
          expect(receiver).to have_received(:starting)
        end

        it 'should receive task' do
          expect(receiver).to have_received(:starting).with(hash_including({ task: kind_of(Rake::Task) }))
          end

        it 'should receive task arguments' do
          expect(receiver).to have_received(:starting).with(hash_including({ args: kind_of(Rake::TaskArguments) }))
        end
      end

      describe 'finished handler' do
        it 'should run' do
          expect(receiver).to have_received(:finished)
        end

        it 'should receive task' do
          expect(receiver).to have_received(:finished).with(hash_including({ task: kind_of(Rake::Task) }))
        end

        it 'should receive task arguments' do
          expect(receiver).to have_received(:finished).with(hash_including({ args: kind_of(Rake::TaskArguments) }))
        end

        it 'should not receive error' do
          expect(receiver).to have_received(:finished).with(hash_including({ error: nil }))
        end
      end
    end

    context 'when task fails' do
      let(:error) { Pipeline::ExecutionError.new('task error') }

      before {
        task :task do
          raise error
        end

        begin
          Rake::Task[:task].invoke
        rescue Pipeline::ExecutionError
        end
      }

      it 'should receive error' do
        expect(receiver).to have_received(:finished).with(hash_including({ error: error }))
      end
    end
  end
end
