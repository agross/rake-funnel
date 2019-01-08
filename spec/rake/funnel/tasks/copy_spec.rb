# frozen_string_literal: true

describe Rake::Funnel::Tasks::Copy do
  before do
    Rake::Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :copy }
    its(:source) { should eq([]) }
    its(:target) { should be_nil }
  end

  describe 'execution' do
    let(:source) { %w(one two) }
    let(:target) { 'target' }
    let(:finder) { instance_double(Rake::Funnel::Support::Finder).as_null_object }

    before do
      allow(finder).to receive(:all_or_default).and_return(source)
      allow(Rake::Funnel::Support::Finder).to receive(:new).and_return(finder)
      allow(Rake::Funnel::Support::Copier).to receive(:copy)
    end

    subject do
      described_class.new do |t|
        t.source = source
        t.target = target
      end
    end

    before do
      Rake::Task[subject.name].invoke
    end

    it 'should delegate to Copier' do
      expect(Rake::Funnel::Support::Copier).to have_received(:copy).with(source, subject.target)
    end
  end
end
