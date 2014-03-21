require 'rake'
require 'pipeline'

describe Pipeline::Tasks::Timing do

  include Rake::DSL

  before {
    Rake.application = nil
    Rake::Task.clear

    define_tasks.should be
    subject.should be
  }

  let(:define_tasks) { task :task }

  after {
    subject.reset!
  }

  describe 'defaults' do
    its(:name) { should == :timing }
    its(:stats) { should have(0).items }

    it 'should add itself to the top level tasks' do
      Rake.application.top_level_tasks.should include(:timing)
    end

    it 'should append itself to the top level tasks' do
      Rake.application.stub(:handle_options)
      Rake.application.init

      Pipeline::Tasks::Timing.new

      Rake.application.top_level_tasks.should have_at_least(2).items
      Rake.application.top_level_tasks.last.should == :timing
    end
  end

  describe 'execution' do
    before {
      Rake.application.stub(:init)
      Rake.application.stub(:load_rakefile)
      Rake.application.top_level_tasks.unshift(:task)
      Rake.application.stub(:exit_because_of_exception)

      $stdout.stub(:puts)
      $stderr.stub(:puts)
      # The 'rake aborted!' message is #printed on $stderr.
      $stderr.stub(:print)

      Rake.application.run
    }

    context 'with task defined' do
      let(:define_tasks) {
        task :task do
          puts 'hello'
        end
      }

      it 'should execute tasks' do
        expect($stdout).to have_received(:puts).with('hello')
      end

      it 'should record timing information for executed tasks' do
        subject.stats.should have(2).items
        subject.stats.first[:task].name.should == 'task'
        subject.stats.first[:time].should be_a(Float)
      end

      it 'should record timing information for itself' do
        subject.stats.should have(2).items

        # Ruby has no #last on Enumerable, WTF.
        subject.stats.reverse_each.first[:task].name.should == 'timing'
      end
    end

    context 'with unreachable task defined' do
      let(:define_tasks) {
        task :task
        task :not_executed
      }

      it 'should not record timing information for unexecuted tasks' do
        subject.stats.map { |s| s[:task].name }.should_not include('not_executed')
      end
    end

    describe 'build finished' do
      context 'when rake succeeded' do
        it 'should print the report' do
          expect($stdout).to have_received(:puts).with(/Build time report/)
        end

        it 'should report success' do
          expect($stdout).to have_received(:puts).with(/Status\s+OK/)
        end
      end

      context 'when rake failed' do
        let(:define_tasks) {
          task :task do
            raise
          end
        }

        it 'should print the report' do
          expect($stdout).to have_received(:puts).with(/Build time report/)
        end

        it 'should report failure' do
          expect($stderr).to have_received(:puts).with(/Status\s+Failed/)
        end
      end
    end
  end
end
