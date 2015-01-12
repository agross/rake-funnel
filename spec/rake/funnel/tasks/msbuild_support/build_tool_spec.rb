describe Rake::Funnel::Tasks::MSBuildSupport::BuildTool do
  before {
    allow(Rake::Win32).to receive(:windows?).and_return(windows?)
  }

  context 'on Windows', platform: :win32 do
    let(:windows?) { true }

    it 'should find msbuild.exe' do
      expect(described_class.find).to match(/msbuild\.exe$/)
    end
  end

  context 'not on Windows' do
    let(:windows?) { false }

    it 'should find xbuild' do
      expect(described_class.find).to eq('xbuild')
    end
  end
end
