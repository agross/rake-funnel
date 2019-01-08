# frozen_string_literal: true

describe Rake::Funnel::Tasks::AssemblyVersion do
  before do
    Rake::Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :version }
    its(:language) { should == :cs }
    its(:source) { should == :FromVersionFiles }
    its(:source_args) { should == {} }
    its(:target_path) { should be_an_instance_of(Proc) }
  end

  describe '#next_to_source' do
    it 'should place VersionInfo next to source' do
      expect(described_class.new.next_to_source(:cs, {}, 'blah/VERSION')).to eq('blah/VersionInfo.cs')
    end
  end

  describe 'execution' do
    let(:writer) { instance_double(Rake::Funnel::Support::AssemblyVersionWriter).as_null_object }

    before do
      allow(Rake::Funnel::Support::AssemblyVersionWriter).to receive(:new).and_return(writer)
    end

    subject do
      described_class.new(:name) do |t|
        t.language = %i(cs vb)
        t.source = %w(one two)
        t.source_args = { foo: 42 }
        t.target_path = 'will not work'
      end
    end

    before do
      Rake::Task[subject.name].invoke
    end

    it 'should pass source and source_args' do
      expect(Rake::Funnel::Support::AssemblyVersionWriter).to have_received(:new)
        .with(subject.source, subject.source_args)
    end

    it 'should use writer' do
      expect(writer).to have_received(:write).with(subject.target_path, subject.language)
    end
  end
end
