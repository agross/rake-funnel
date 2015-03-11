include Rake
include Rake::Funnel::Support

describe Rake::Funnel::Tasks::Copy do
  before {
    CLEAN.clear
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :copy }
    its(:source) { should eq([]) }
    its(:target) { should be_nil }

    it 'should not add the target file to the files to be cleaned' do
      expect(CLEAN).to be_empty
    end

    describe 'overriding defaults' do
      subject {
        described_class.new do |t|
          t.target = 'something'
        end
      }

      it 'should add the target file to the files to be cleaned' do
        expect(CLEAN).to include(subject.target)
      end
    end
  end

  describe 'execution' do
    let(:source) { %w(bin/1 bin/2 bin/3/4 bin/directory/file bin/directory bin/directory-no-content) }
    let(:target) { 'some path' }

    subject! {
      described_class.new do |t|
        t.source = source
        t.target = target
      end
    }

    context 'failure' do
      context 'target not defined' do
        let(:target) { nil }

        it 'should fail' do
          expect { Task[subject.name].invoke }.to raise_error(/Target not defined/)
        end
      end
    end

    context 'success' do
      let(:finder) { double(Finder).as_null_object }

      before {
        allow(finder).to receive(:all_or_default).and_return(source)
        allow(Finder).to receive(:new).and_return(finder)

        allow(File).to receive(:directory?).and_return(false)
        source.last(2).each do |dir|
          allow(File).to receive(:directory?).with(dir).and_return(true)
        end

        allow(RakeFileUtils).to receive(:mkdir_p)
        allow(RakeFileUtils).to receive(:cp)
      }

      before {
        Task[subject.name].invoke
      }

      def no_prefix(file)
        file.sub(%r|bin/|, '')
      end

      it 'should create target directories' do
        expect(RakeFileUtils).to have_received(:mkdir_p).with(subject.target + '/3')
        expect(RakeFileUtils).to have_received(:mkdir_p).with(subject.target + '/directory')
      end

      it 'should skip source directories' do
        source
          .select { |src| File.directory?(src) }
          .each do |src|
          expect(RakeFileUtils).not_to have_received(:cp).with(src, anything)
        end
      end

      it 'should copy files with common path removed' do
        source
          .select { |src| !File.directory?(src) }
          .each do |src|
          expect(RakeFileUtils).to have_received(:cp).with(src, File.join(subject.target, no_prefix(src)), { preserve: true })
        end
      end
    end
  end
end
