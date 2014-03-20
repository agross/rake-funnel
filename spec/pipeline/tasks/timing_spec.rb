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
