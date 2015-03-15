describe Rake::Funnel::Support::BinaryVersionReader do
  def binary_version(*version_parts)
    version = version_parts.map { |p| p.to_s + "\0" }.join(".\0")
    "F\0i\0l\0e\0V\0e\0r\0s\0i\0o\0n" + "\0" * 3 + version + "\0" * 3
  end

  let(:file) { 'some assembly' }

  before {
    allow(File).to receive(:binread).with(file).and_return(contents)
  }

  describe 'version can be read' do
    let(:version) { %w(1 2 3 4) }
    let(:contents) { "binary #{binary_version(*version)} binary" }

    it 'should yield all parts' do
      expect(described_class.read_from(file).file_version).to eq(version.join('.'))
    end
  end

  describe 'version cannot be read' do
    let(:contents) { 'this does not contain a version number' }

    it 'should yield empty VersionInfo' do
      expect(described_class.read_from(file).to_h).to be_empty
    end
  end
end
