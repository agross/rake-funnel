# frozen_string_literal: true

describe Rake::Funnel::Support::AssemblyVersion::FromVersionFiles do
  describe 'defaults' do
    its(:search_pattern) { should == %w(**/VERSION) }
    its(:metadata) { should be_nil }

    describe 'overriding defaults' do
      subject do
        described_class.new(search_pattern: 'search pattern',
                            metadata: {})
      end

      its(:search_pattern) { should == 'search pattern' }
      its(:metadata) { should == {} }
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
    let(:finder) { instance_double(Rake::Funnel::Support::Finder).as_null_object }
    let(:files) { %w(1 2) }

    before do
      allow(finder).to receive(:all_or_default).and_return(files)
      allow(Rake::Funnel::Support::Finder).to receive(:new).and_return(finder)
    end

    before do
      allow(Rake::Funnel::Support::VersionInfo).to \
        receive(:read_version_from).and_return(*files)
    end

    before do
      allow($stderr).to receive(:print)
    end

    subject do
      described_class.new(metadata: { pre: 'alpha', build: 42, sha: 'abc' })
    end

    it 'should yield source and version info for each file' do
      args = files.map do |file|
        {
          source: file,
          version_info: Rake::Funnel::Support::VersionInfo.parse(version: file, metadata: {
                                                                   pre: subject.metadata[:pre],
                                                                   build: subject.metadata[:build],
                                                                   sha: subject.metadata[:sha]
                                                                 })
        }
      end

      expect { |b| subject.each(&b) }.to yield_successive_args(*args)
    end
  end
end
