include Rake
include Rake::Funnel::Support

describe Rake::Funnel::Tasks::Copy do
  before {
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :copy }
    its(:source) { should eq([]) }
    its(:target) { should be_nil }
  end

  describe 'execution' do
    let(:source) { %w(one two) }
    let(:target) { 'target' }
    let(:finder) { instance_double(Finder).as_null_object }

    before {
      allow(finder).to receive(:all_or_default).and_return(source)
      allow(Finder).to receive(:new).and_return(finder)
    }

    before {
      allow(Copier).to receive(:copy)
    }

    subject {
      described_class.new do |t|
        t.source = source
        t.target = target
      end
    }

    before {
      Task[subject.name].invoke
    }

    it 'should delegate to Copier' do
      expect(Copier).to have_received(:copy).with(source, subject.target)
    end
  end
end
