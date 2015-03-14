include Rake
include Rake::Funnel::Support

describe Rake::Funnel::Tasks::AssemblyVersion do
  before {
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :version }
    its(:language) { should == :cs }
    its(:source) { should == :FromVersionFiles }
    its(:source_args) { should == {} }
    its(:target_path) { should be_an_instance_of(Proc) }
  end

  describe 'execution' do
    let(:writer) { instance_double(AssemblyVersionWriter).as_null_object }

    before {
      allow(AssemblyVersionWriter).to receive(:new).and_return(writer)
    }

    subject {
      described_class.new(:name) do |t|
        t.language = [:cs, :vb]
        t.source = %w(one two)
        t.source_args = { foo: 42 }
        t.target_path = 'will not work'
      end
    }

    before {
      Task[subject.name].invoke
    }

    it 'should pass source and source_args' do
      expect(AssemblyVersionWriter).to have_received(:new).with(subject.source, subject.source_args)
    end

    it 'should use writer' do
      expect(writer).to have_received(:write).with(subject.target_path, subject.language)
    end
  end
end
