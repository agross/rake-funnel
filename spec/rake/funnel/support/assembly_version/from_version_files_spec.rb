include Rake::Funnel::Support

describe Rake::Funnel::Support::AssemblyVersion::FromVersionFiles do
  describe 'defaults' do
    its(:search_pattern) { should == %w(**/VERSION) }
    its(:build_number) { should be_nil }
    its(:sha) { should be_nil }

    describe 'overriding defaults' do
      subject {
        described_class.new({
            search_pattern: 'search pattern',
            build_number: 42,
            sha: 'abc'
          })
      }

      its(:search_pattern) { should == 'search pattern' }
      its(:build_number) { should == 42 }
      its(:sha) { should == 'abc' }
    end
  end

  describe 'enumerable' do
    it { is_expected.to be_kind_of(Enumerable) }
    it { is_expected.to respond_to(:each) }

    it 'should yield enumerator' do
      expect(subject.each).to be_kind_of(Enumerator)
    end
  end

  describe 'enumeration' do
    let(:finder) { double(Finder).as_null_object }
    let(:files) { %w(1 2) }

    before {
      allow(finder).to receive(:all_or_default).and_return(files)
      allow(Finder).to receive(:new).and_return(finder)
    }

    before {
      allow(VersionInfo).to receive(:read_version_from).and_return(*files)
    }

    before {
      allow(Rake).to receive(:rake_output_message)
    }

    subject {
      described_class.new({ build_number: 42, sha: 'abc' })
    }

    it 'should yield source and version info for each file' do
      expect { |b| subject.each(&b) }.to yield_successive_args(
          { source: '1', version_info: VersionInfo.new({ assembly_version: '1', assembly_file_version: '1.42', assembly_informational_version: '1.42-abc' }) },
          { source: '2', version_info: VersionInfo.new({ assembly_version: '2', assembly_file_version: '2.42', assembly_informational_version: '2.42-abc' }) }
        )
    end
  end
end
