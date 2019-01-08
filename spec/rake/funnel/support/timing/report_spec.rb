# frozen_string_literal: true

describe Rake::Funnel::Support::Timing::Report do
  include Rake::DSL

  subject { described_class.new(stats, opts) }

  let(:opts) { {} }

  before do
    allow($stdout).to receive(:print)
    allow($stderr).to receive(:print)
    subject.render
  end

  shared_examples_for 'report' do
    it 'should separator lines' do
      expect($stdout).to have_received(:print)
        .with(Regexp.new('-' * described_class::HEADER_WIDTH)).exactly(4).times
    end

    it 'should print the header' do
      expect($stdout).to have_received(:print).with("Build time report\n")
    end

    it 'should print the total time' do
      expect($stdout).to have_received(:print).with(/^Total\s+00:00:00/)
    end

    it 'should print the build status' do
      expect($stdout).to have_received(:print).with(/Status\s+OK/)
    end

    context 'when rake succeeded' do
      let(:opts) { { failed: false } }

      it 'should print the successful build status' do
        expect($stdout).to have_received(:print).with(/Status\s+OK/)
      end
    end

    context 'when rake failed' do
      let(:opts) { { failed: true } }

      it 'should print the failed build status' do
        expect($stderr).to have_received(:print).with(/Status\s+Failed/)
      end
    end
  end

  describe 'empty report', include: Rake::Funnel::Support::Timing do
    let(:stats) { Rake::Funnel::Support::Timing::Statistics.new }

    it_behaves_like 'report'
  end

  describe 'report for 2 tasks' do
    let(:stats) do
      s = Rake::Funnel::Support::Timing::Statistics.new
      s.benchmark(task(:foo)) {}
      s.benchmark(task(:bar)) {}
      s
    end

    it_behaves_like 'report'

    it 'should print each task' do
      expect($stdout).to have_received(:print).with(/^foo/)
      expect($stdout).to have_received(:print).with(/^bar/)
    end

    it "should print each task's time" do
      expect($stdout).to have_received(:print).with(/00:00:00/).exactly(3).times
    end
  end

  describe 'formatting' do
    let(:stats) do
      s = Rake::Funnel::Support::Timing::Statistics.new
      s.benchmark(task(task_name)) {}
      s
    end

    let(:header_space) do
      diff = task_name.to_s.length - subject.columns[0].header.length
      diff = 0 if diff < 0
      diff + described_class::SPACE
    end

    let(:header_underline) do
      [subject.columns[0].header.length, task_name.to_s.length].max
    end

    let(:value_space) do
      diff = subject.columns.first.header.length - task_name.to_s.length
      diff = 0 if diff < 0
      diff + described_class::SPACE
    end

    shared_examples_for 'padding' do
      it 'should pad headers' do
        expect($stdout).to have_received(:print)
          .with(Regexp.new("^#{subject.columns[0].header}\\s{#{header_space}}#{subject.columns[1].header}"))
      end

      it 'should pad header underlines' do
        expect($stdout).to have_received(:print).with(Regexp.new("^-{#{header_underline}}\\s+"))
      end

      it 'should pad the task names' do
        expect($stdout).to have_received(:print).with(Regexp.new("^#{task_name}\\s{#{value_space}}\\d"))
      end
    end

    context 'task names are shorter than headers' do
      let(:task_name) { :a }

      it_behaves_like 'padding'
    end

    context 'task names are longer than headers' do
      let(:task_name) { :aaaaaaaaaaaa }

      it_behaves_like 'padding'
    end
  end
end
