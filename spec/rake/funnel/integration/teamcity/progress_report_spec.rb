# frozen_string_literal: true

describe Rake::Funnel::Integration::TeamCity::ProgressReport do # rubocop:disable RSpec/FilePath
  include Rake::DSL

  let(:teamcity_running?) { false }
  let(:teamcity_rake_runner?) { false }

  before do
    allow(Rake::Funnel::Integration::TeamCity).to receive(:running?).and_return(teamcity_running?)
    allow(Rake::Funnel::Integration::TeamCity).to receive(:rake_runner?).and_return(teamcity_rake_runner?)
    allow(Rake::Funnel::Integration::TeamCity::ServiceMessages).to receive(:block_opened)
    allow(Rake::Funnel::Integration::TeamCity::ServiceMessages).to receive(:block_closed)
    allow(Rake::Funnel::Integration::TeamCity::ServiceMessages).to receive(:progress_start)
    allow(Rake::Funnel::Integration::TeamCity::ServiceMessages).to receive(:progress_finish)
    allow(Rake::Funnel::Integration::TeamCity::ServiceMessages).to receive(:build_problem)

    Rake::Task.clear
  end

  subject! do
    described_class.new
  end

  after do
    subject.disable!
  end

  shared_examples 'block report' do
    it 'should write block start' do
      expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).to \
        have_received(:block_opened).with(name: 'task')
    end

    it 'should write block end' do
      expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).to \
        have_received(:block_closed).with(name: 'task')
    end
  end

  shared_examples 'no block report' do
    it 'should not write block start' do
      expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).not_to \
        have_received(:block_opened)
    end

    it 'should not write block end' do
      expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).not_to \
        have_received(:block_closed)
    end
  end

  context 'when task succeeds' do
    before do
      task :task

      Rake::Task[:task].invoke
    end

    it 'should not report build problems' do
      expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).not_to \
        have_received(:build_problem)
    end

    context 'not on TeamCity' do
      it_behaves_like 'no block report'
    end

    context 'on TeamCity' do
      let(:teamcity_running?) { true }

      context 'without rake runner' do
        it_behaves_like 'block report'
      end

      context 'with rake runner' do
        let(:teamcity_rake_runner?) { true }

        it_behaves_like 'no block report'
      end
    end
  end

  context 'when task fails' do
    class SpecificError < StandardError; end

    before do
      module Rake
        class ApplicationAbortedException < StandardError
          attr_reader :inner_exception

          def initialize(other_exception)
            @inner_exception = other_exception
          end
        end
      end
    end

    let(:error) { SpecificError.new('task error' * 4000) }

    before do
      task :task do
        raise error
      end

      begin
        Rake::Task[:task].invoke
      rescue Rake::ApplicationAbortedException, SpecificError => e
        @raised_error = e
      end
    end

    context 'not on TeamCity' do
      it_behaves_like 'no block report'

      it 'should not swallow the error' do
        expect(@raised_error).to be_a_kind_of(SpecificError) # rubocop:disable RSpec/InstanceVariable
      end
    end

    context 'on TeamCity' do
      let(:teamcity_running?) { true }

      describe 'build problems' do
        it 'should report build problems' do
          expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).to \
            have_received(:build_problem)
        end

        it 'should report the error message' do
          expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).to \
            have_received(:build_problem)
            .with(hash_including(description: be_an_instance_of(String)))
        end

        it 'should report the first 4000 characters of the error message' do
          expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).to \
            have_received(:build_problem)
            .with(hash_including(description: have(4000).items))
        end
      end

      context 'without rake runner' do
        it_behaves_like 'block report'

        it 'should report the error as a build problem' do
          expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).to \
            have_received(:build_problem)
        end
      end

      context 'with rake runner' do
        let(:teamcity_rake_runner?) { true }
        let(:error) do
          Rake::ApplicationAbortedException.new(SpecificError.new('inner message'))
        end

        it 'should report the inner error as a build problem (as it will be wrapped in a ApplicationAbortedException)' do # rubocop:disable Metrics/LineLength
          expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).to \
            have_received(:build_problem).with(description: 'inner message')
        end

        it_behaves_like 'no block report'
      end
    end
  end

  context 'when progess report was disabled' do
    let(:teamcity_running?) { true }

    before do
      subject.disable!

      task :task

      Rake::Task[:task].invoke
    end

    it 'should not write' do
      expect(Rake::Funnel::Integration::TeamCity::ServiceMessages).not_to \
        have_received(:block_opened)
    end
  end
end
