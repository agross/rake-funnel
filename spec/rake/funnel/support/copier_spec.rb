describe Rake::Funnel::Support::Copier do
  let(:source) { files + directories }
  let(:files) { %w(bin/1 bin/2 bin/3/4 bin/directory/file) }
  let(:directories) { %w(bin/directory bin/directory-no-content) }
  let(:target) { 'target path' }

  context 'failure' do
    context 'target not defined' do
      let(:target) { nil }

      it 'should fail' do
        expect { described_class.copy([], nil) }.to raise_error(/Target not defined/)
      end
    end
  end

  describe 'recursive copy' do
    before {
      allow(File).to receive(:directory?).and_return(false)
      directories.each do |dir|
        allow(File).to receive(:directory?).with(dir).and_return(true)
      end

      allow(RakeFileUtils).to receive(:mkdir_p)
      allow(RakeFileUtils).to receive(:cp)
    }

    before {
      described_class.copy(source, target)
    }

    def no_prefix(file)
      file.sub(%r|bin/|, '')
    end

    it 'should create target directories' do
      expect(RakeFileUtils).to have_received(:mkdir_p).with(File.join(target, '3'))
      expect(RakeFileUtils).to have_received(:mkdir_p).with(File.join(target, 'directory'))
    end

    it 'should skip source directories' do
      directories.each do |dir|
        expect(RakeFileUtils).not_to have_received(:cp).with(dir, anything)
      end
    end

    it 'should copy files with common path removed' do
      files.each do |file|
        target_path = File.join(target, no_prefix(file))
        expect(RakeFileUtils).to have_received(:cp).with(file, target_path, anything)
      end
    end

    it 'should preserve metdata' do
      expect(RakeFileUtils).to have_received(:cp).with(anything, anything, { preserve: true }).exactly(files.length).times
    end
  end
end
