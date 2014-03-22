require 'rake'
require 'pipeline'

include Pipeline::Integration

describe TeamCityBlocks do

  include Rake::DSL

  let(:reset) { false }

  before {
    Rake::Task.clear

    task :task

    TeamCity.stub(:running?)
    TeamCity.stub(:block_opened)
    TeamCity.stub(:block_closed)

    class Foo
      include TeamCityBlocks
    end

    TeamCityBlocks.reset! if reset

    Rake::Task[:task].invoke
  }

  after { TeamCityBlocks.reset! }

  describe 'running a rake task' do
    it 'should write block start' do
      expect(TeamCity).to have_received(:block_opened).with(name: 'task')
    end

    it 'should write block end' do
      expect(TeamCity).to have_received(:block_closed).with(name: 'task')
    end

    it 'should write block end if task fails' do
      expect(TeamCity).to have_received(:block_closed).with(name: 'task')
    end
  end

  context 'when the module has been included twice' do
    before {
      class Bar
        include TeamCityBlocks
      end
    }

    it 'should write only once' do
      expect(TeamCity).to have_received(:block_opened).with(name: 'task').once
    end
  end

  context 'when the module is reset' do
    let(:reset) { true }

    it 'should not write' do
      expect(TeamCity).to_not have_received(:block_opened)
    end
  end
end
