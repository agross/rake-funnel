include Rake
include Rake::Funnel::Support

describe Rake::Funnel::Tasks::Zip do
  before {
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :package }
    its(:source) { should eq([]) }
    its(:target) { should be_nil }
    its(:zip_root) { should be_nil }
  end

  describe 'execution' do
    let(:source) { %w(bin/1 bin/2 bin/3/4) }
    let(:finder) { instance_double(Finder).as_null_object }

    before {
      allow(finder).to receive(:all_or_default).and_return(source)
      allow(Finder).to receive(:new).and_return(finder)
    }

    before {
      allow(Zipper).to receive(:zip)
      allow(Rake).to receive(:rake_output_message)
    }

    subject {
      described_class.new do |t|
        t.source = source
        t.target = 'some path/file.zip'
        t.zip_root = 'zip root'
      end
    }

    before {
      Task[subject.name].invoke
    }

    it 'should delegate to Zipper' do
      expect(Zipper).to have_received(:zip).with(subject.source, subject.target, subject.zip_root)
    end

    it 'should report the created zip file' do
      expect(Rake).to have_received(:rake_output_message).with("Created #{subject.target}")
    end
  end
end
