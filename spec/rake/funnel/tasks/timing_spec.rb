describe Rake::Funnel::Tasks::Timing do
  include Rake::DSL

  before do
    Rake.application = nil
    Rake::Task.clear
  end

  let(:define_tasks) { task :task }

  subject! do
    define_tasks
    described_class.new
  end

  after do
    subject.reset!
  end

  describe 'defaults' do
    its(:name) { should == :timing }
    its(:stats) { should have(0).items }
  end

  describe 'task is automatically executed' do
    it 'should add itself to the top level tasks' do
      expect(Rake.application.top_level_tasks).to include(:timing)
    end

    it 'should append itself to the top level tasks' do
      allow(Rake.application).to receive(:handle_options).and_return([])
      Rake.application.init

      described_class.new

      expect(Rake.application.top_level_tasks).to have_at_least(2).items
      expect(Rake.application.top_level_tasks.last).to eq(:timing)
    end

    context 'task defined in namespace' do
      it 'should add namespaced top level task' do
        allow(Rake.application).to receive(:handle_options).and_return([])
        Rake.application.init

        namespace :namespace do
          described_class.new
        end

        expect(Rake.application.top_level_tasks).to include('namespace:timing')
      end
    end
  end

  describe 'execution' do
    before do
      allow(Rake.application).to receive(:init)
      allow(Rake.application).to receive(:load_rakefile)
      Rake.application.top_level_tasks.unshift(:task)
      allow(Rake.application).to receive(:exit_because_of_exception)

      allow($stdout).to receive(:puts)
      allow(Kernel).to receive(:warn)
      # The 'rake aborted!' message is #printed on $stderr.
      allow($stderr).to receive(:print)

      Rake.application.run
    end

    context 'with task defined' do
      let(:define_tasks) do
        task :task do
          puts 'hello'
        end
      end

      it 'should execute tasks' do
        expect($stdout).to have_received(:puts).with('hello')
      end

      it 'should record timing information for executed tasks' do
        expect(subject.stats).to have(2).items
        expect(subject.stats.first[:task].name).to eq('task')
        expect(subject.stats.first[:time]).to be_a(Float)
      end

      it 'should record timing information for itself' do
        expect(subject.stats).to have(2).items

        # Ruby has no #last on Enumerable, WTF.
        expect(subject.stats.reverse_each.first[:task].name).to eq('timing')
      end
    end

    context 'with unreachable task defined' do
      let(:define_tasks) do
        task :task
        task :not_executed
      end

      it 'should not record timing information for unexecuted tasks' do
        expect(subject.stats.map { |s| s[:task].name }).not_to include('not_executed')
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
        let(:define_tasks) do
          task :task do
            raise
          end
        end

        it 'should print the report' do
          expect($stdout).to have_received(:puts).with(/Build time report/)
        end

        it 'should report failure' do
          expect(Kernel).to have_received(:warn).with(/Status\s+Failed/)
        end
      end
    end
  end
end
