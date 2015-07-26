describe Rake::Funnel::Support::MSBuild::BuildTool do
  before {
    allow(Rake::Win32).to receive(:windows?).and_return(windows?)
  }

  context 'on Windows', platform: :win32 do
    let(:windows?) { true }

    before {
      allow(::Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).and_yield({ 'MSBuildToolsPath' => 'path'})
    }

    it 'should search the registry for known MSBuild versions' do
      described_class.find
      expect(::Win32::Registry::HKEY_LOCAL_MACHINE).to have_received(:open).at_least(:once)
    end

    context 'MSBuild exists' do
      before {
        allow(File).to receive(:exist?).with('path/msbuild.exe').and_return(true)
      }

      it 'should find msbuild.exe' do
        expect(described_class.find).to eq('path/msbuild.exe')
      end
    end

    context 'MSBuild does not exist' do
      before {
        allow(File).to receive(:exist?).with('path/msbuild.exe').and_return(false)
      }

      it 'should not find msbuild.exe' do
        expect(described_class.find).to be_nil
      end
    end
  end

  context 'not on Windows' do
    let(:windows?) { false }

    it 'should find xbuild' do
      expect(described_class.find).to eq('xbuild')
    end
  end
end
