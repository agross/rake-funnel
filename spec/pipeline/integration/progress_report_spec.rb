require 'rake'
require 'pipeline'

include Pipeline::Integration

describe ProgressReport do

  include Rake::DSL

  let!(:report) { described_class.new }

  let(:teamcity_running?) { false }
  let(:teamcity_rake_runner?) { false }

  before { $stdout.stub(:puts) }

  before {
    TeamCity.stub(:running?).and_return(teamcity_running?)
    TeamCity.stub(:rake_runner?).and_return(teamcity_rake_runner?)
    TeamCity.stub(:block_opened)
    TeamCity.stub(:block_closed)
    TeamCity.stub(:progress_start)
    TeamCity.stub(:progress_finish)
    TeamCity.stub(:build_problem)
  }

  before { Rake::Task.clear }

  after { report.reset! }

  describe 'defaults' do
    shared_examples :block_report do
      it 'should write block start' do
        expect(TeamCity).to have_received(:block_opened).with(name: 'task')
      end

      it 'should write progress start' do
        expect(TeamCity).to have_received(:progress_start).with('task')
      end

      it 'should write progress finish' do
        expect(TeamCity).to have_received(:progress_finish).with('task')
      end

      it 'should write block end' do
        expect(TeamCity).to have_received(:block_closed).with(name: 'task')
      end
    end

    shared_examples :no_block_report do
      it 'should not write block start' do
        expect(TeamCity).not_to have_received(:block_opened)
      end

      it 'should not write progress start' do
        expect(TeamCity).not_to have_received(:progress_start)
      end

      it 'should not write progress finish' do
        expect(TeamCity).not_to have_received(:progress_finish)
      end

      it 'should not write block end' do
        expect(TeamCity).not_to have_received(:block_closed)
      end
    end

    context 'when task succeeds' do
      before {
        task :task

        Rake::Task[:task].invoke
      }

      it 'should not report build problems' do
        expect(TeamCity).to_not have_received(:build_problem)
      end

      context 'not on TeamCity' do
        it_behaves_like :block_report

        it 'should write task name in square brackets' do
          expect($stdout).to have_received(:puts).with("\n[task]")
        end
      end

      context 'on TeamCity' do
        let(:teamcity_running?) { true }

        it 'should not write task name in square brackets since it would clutter the output' do
          expect($stdout).to_not have_received(:puts).with("\n[task]")
        end

        context 'without rake runner' do
          it_behaves_like :block_report
        end

        context 'with rake runner' do
          let(:teamcity_rake_runner?) { true }

          it_behaves_like :no_block_report
        end
      end
    end

    context 'when task fails' do
      before {
        module Rake
          class ApplicationAbortedException < StandardError
            attr_reader :inner_exception

            def initialize(other_exception)
              @inner_exception = other_exception
            end
          end
        end
      }

      let(:error) { Pipeline::ExecutionError.new('task error' * 4000) }

      before {
        task :task do
          raise error
        end

        begin
          Rake::Task[:task].invoke
        rescue Rake::ApplicationAbortedException => e
        rescue Pipeline::ExecutionError => e
          @raised_error = e
        end
      }

      context 'not on TeamCity' do
        it_behaves_like :block_report

        it 'should not swallow the error' do
          @raised_error.should be_a_kind_of(Pipeline::ExecutionError)
        end
      end

      context 'on TeamCity' do
        let(:teamcity_running?) { true }

        describe 'build problems' do
          it 'should report build problems' do
            expect(TeamCity).to have_received(:build_problem)
          end

          it 'should report the error message' do
            expect(TeamCity).to have_received(:build_problem).with(hash_including({ description: be_an_instance_of(String) }))
          end

          it 'should report the first 4000 characters of the error message' do
            expect(TeamCity).to have_received(:build_problem).with(hash_including({ description: have(4000).items }))
          end
        end

        context 'without rake runner' do
          it_behaves_like :block_report

          it 'should report the error as a build problem' do
            expect(TeamCity).to have_received(:build_problem)
          end
        end

        context 'with rake runner' do
          let(:teamcity_rake_runner?) { true }
          let(:error) {
            Rake::ApplicationAbortedException.new(StandardError.new('inner message'))
          }

          it 'should report the inner error as a build problem (as it will be wrapped in a ApplicationAbortedException)' do
            expect(TeamCity).to have_received(:build_problem).with({ description: 'inner message' })
          end
        end
      end
    end

    context 'when report was reset' do
      let(:teamcity_running?) { true }

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
