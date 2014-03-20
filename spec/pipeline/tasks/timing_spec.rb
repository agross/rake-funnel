require 'rake'
require 'pipeline'

describe Pipeline::Tasks::Timing do

  include Rake::DSL

  before { Rake.application = nil }

  describe 'defaults' do
    its(:name) { should == :timing }
    its(:stats) { should have(0).items }

    it 'should add itself to the top level tasks' do
      subject.should be

      Rake.application.top_level_tasks.should include(:timing)
    end

    it 'should append itself to the top level tasks' do
      Rake.application.stub(:handle_options)
      Rake.application.init

      subject.should be

      Rake.application.top_level_tasks.should have_at_least(2).items
      Rake.application.top_level_tasks.last.should == :timing
    end
  end

  describe 'execution' do

    before { subject.should be }

    it 'should execute tasks' do
      output = double.as_null_object

      task :task do
        output.print 'hello from task'
      end

      Rake::Task[:task].invoke

      expect(output).to have_received(:print).with('hello from task')
    end

    it 'should record timing information for executed tasks' do
      task :task

      Rake::Task[:task].invoke

      subject.stats.should have(1).items
      subject.stats.first[:task].name.should == 'task'
      subject.stats.first[:time].should be_a(Float)
    end

    it 'should not record timing information for unexecuted tasks' do
      task :task

      subject.stats.should have(0).items
    end

    it 'should print the report' do
      task :default

      Rake.application.stub(:handle_options)
      $stdout.stub(:puts)

      Rake.application.top_level

      expect($stdout).to have_received(:puts).with(/Build time report/)
    end
  end
end

describe Pipeline::Tasks::Timing::Report do

  include Rake::DSL

  subject do
    Pipeline::Tasks::Timing::Report.new(stats, opts)
  end

  let(:opts) { {} }

  before {
    $stdout.stub(:puts)
    subject.render
  }

  shared_examples_for :report do
    it 'should separator lines' do
      expect($stdout).to have_received(:puts).with(Regexp.new('-' * Pipeline::Tasks::Timing::Report::HEADER_WIDTH)).exactly(4).times
    end

    it 'should print the header' do
      expect($stdout).to have_received(:puts).with('Build time report')
    end

    it 'should print the total time' do
      expect($stdout).to have_received(:puts).with(/^Total\s+00:00:00/)
    end

    it 'should print the build status' do
      expect($stdout).to have_received(:puts).with(/Status\s+OK/)
    end

    context 'when rake succeeded' do
      let(:opts) { { :failed => false } }

      it 'should print the successful build status' do
        expect($stdout).to have_received(:puts).with(/Status\s+OK/)
      end
    end

    context 'when rake failed' do
      let(:opts) { { :failed => true } }

      it 'should print the failed build status' do
        expect($stdout).to have_received(:puts).with(/Status\s+Failed/)
      end
    end
  end

  describe 'empty report' do
    let(:stats) {
      Pipeline::Tasks::Timing::Statistics.new
    }

    it_should_behave_like :report
  end

  describe 'report for 2 tasks' do
    let(:stats) {
      s = Pipeline::Tasks::Timing::Statistics.new
      s.benchmark(task :foo) { }
      s.benchmark(task :bar) { }
      s
    }

    it_should_behave_like :report

    it 'should print each task' do
      expect($stdout).to have_received(:puts).with(/^foo/)
      expect($stdout).to have_received(:puts).with(/^bar/)
    end

    it "should print each task's time" do
      expect($stdout).to have_received(:puts).with(/00:00:00/).exactly(3).times
    end
  end

  describe 'formatting' do
    let(:stats) {
      s = Pipeline::Tasks::Timing::Statistics.new
      s.benchmark(task task_name) { }
      s
    }

    let(:header_space) {
      diff = task_name.to_s.length - subject.columns[0].header.length
      diff = 0 if diff < 0
      diff + Pipeline::Tasks::Timing::Report::SPACE
    }

    let(:header_underline) {
      [subject.columns[0].header.length, task_name.to_s.length].max
    }

    let(:value_space) {
      diff = subject.columns.first.header.length - task_name.to_s.length
      diff = 0 if diff < 0
      diff + Pipeline::Tasks::Timing::Report::SPACE
    }

    shared_examples_for :padding do
      it 'should pad headers' do
        expect($stdout).to have_received(:puts)
          .with(Regexp.new("^#{subject.columns[0].header}\\s{#{header_space}}#{subject.columns[1].header}"))
      end

      it 'should pad header underlines' do
        expect($stdout).to have_received(:puts).with(Regexp.new("^-{#{header_underline}}\\s+"))
      end

      it 'should pad the task names' do
        expect($stdout).to have_received(:puts).with(Regexp.new("^#{task_name}\\s{#{value_space}}\\d"))
      end
    end

    context 'task names are shorter than headers' do
      let(:task_name) { :a }

      it_should_behave_like :padding
    end

    context 'task names are longer than headers' do
      let(:task_name) { :aaaaaaaaaaaa }

      it_should_behave_like :padding
    end
  end
end
