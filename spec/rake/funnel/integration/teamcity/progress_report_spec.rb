include Rake
include Rake::Funnel::Integration
include Rake::Funnel::Integration::TeamCity

describe Rake::Funnel::Integration::TeamCity::ProgressReport do
  include DSL

  let(:teamcity_running?) { false }
  let(:teamcity_rake_runner?) { false }

  before {
    allow(TeamCity).to receive(:running?).and_return(teamcity_running?)
    allow(TeamCity).to receive(:rake_runner?).and_return(teamcity_rake_runner?)
    allow(ServiceMessages).to receive(:block_opened)
    allow(ServiceMessages).to receive(:block_closed)
    allow(ServiceMessages).to receive(:progress_start)
    allow(ServiceMessages).to receive(:progress_finish)
    allow(ServiceMessages).to receive(:build_problem)

    Task.clear
  }

  subject! {
    described_class.new
  }

  after {
    subject.disable!
  }

  shared_examples :block_report do
    it 'should write block start' do
      expect(ServiceMessages).to have_received(:block_opened).with(name: 'task')
    end

    it 'should write block end' do
      expect(ServiceMessages).to have_received(:block_closed).with(name: 'task')
    end
  end

  shared_examples :no_block_report do
    it 'should not write block start' do
      expect(ServiceMessages).not_to have_received(:block_opened)
    end

    it 'should not write block end' do
      expect(ServiceMessages).not_to have_received(:block_closed)
    end
  end

  context 'when task succeeds' do
    before {
      task :task

      Task[:task].invoke
    }

    it 'should not report build problems' do
      expect(ServiceMessages).to_not have_received(:build_problem)
    end

    context 'not on TeamCity' do
      it_behaves_like :no_block_report
    end

    context 'on TeamCity' do
      let(:teamcity_running?) { true }

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
    class SpecificError < StandardError; end

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

    let(:error) { SpecificError.new('task error' * 4000) }

    before {
      task :task do
        raise error
      end

      begin
        Task[:task].invoke
      rescue ApplicationAbortedException => e
      rescue SpecificError => e
        @raised_error = e
      end
    }

    context 'not on TeamCity' do
      it_behaves_like :no_block_report

      it 'should not swallow the error' do
        expect(@raised_error).to be_a_kind_of(SpecificError)
      end
    end

    context 'on TeamCity' do
      let(:teamcity_running?) { true }

      describe 'build problems' do
        it 'should report build problems' do
          expect(ServiceMessages).to have_received(:build_problem)
        end

        it 'should report the error message' do
          expect(ServiceMessages).to have_received(:build_problem).with(hash_including({ description: be_an_instance_of(String) }))
        end

        it 'should report the first 4000 characters of the error message' do
          expect(ServiceMessages).to have_received(:build_problem).with(hash_including({ description: have(4000).items }))
        end
      end

      context 'without rake runner' do
        it_behaves_like :block_report

        it 'should report the error as a build problem' do
          expect(ServiceMessages).to have_received(:build_problem)
        end
      end

      context 'with rake runner' do
        let(:teamcity_rake_runner?) { true }
        let(:error) {
          ApplicationAbortedException.new(SpecificError.new('inner message'))
        }

        it 'should report the inner error as a build problem (as it will be wrapped in a ApplicationAbortedException)' do
          expect(ServiceMessages).to have_received(:build_problem).with({ description: 'inner message' })
        end

        it_behaves_like :no_block_report
      end
    end
  end

  context 'when progess report was disabled' do
    let(:teamcity_running?) { true }

    before {
      subject.disable!

      task :task

      Task[:task].invoke
    }

    it 'should not write' do
      expect(ServiceMessages).to_not have_received(:block_opened)
    end
  end
end
