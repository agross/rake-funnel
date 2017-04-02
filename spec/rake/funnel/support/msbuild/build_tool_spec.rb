# rubocop:disable RSpec/FilePath

describe Rake::Funnel::Support::MSBuild::BuildTool do
  before do
    allow(Rake::Win32).to receive(:windows?).and_return(windows?)
  end

  context 'on Windows',
          skip: ('Windows Registry not available' unless defined?(::Win32::Registry)) do
    let(:windows?) { true }

    before do
      allow(::Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).and_yield('MSBuildToolsPath' => 'path')
    end

    it 'should search the registry for known MSBuild versions' do
      described_class.find
      expect(::Win32::Registry::HKEY_LOCAL_MACHINE).to have_received(:open).at_least(:once)
    end

    context 'key not found' do
      before do
        allow(::Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).and_raise(::Win32::Registry::Error.new(3))
      end

      it 'finds nothing' do
        expect(described_class.find).to be_nil
      end
    end

    context 'MSBuild exists' do
      before do
        allow(File).to receive(:exist?).with('path/msbuild.exe').and_return(true)
      end

      it 'should find msbuild.exe' do
        expect(described_class.find).to eq('path/msbuild.exe')
      end
    end

    context 'MSBuild does not exist' do
      before do
        allow(File).to receive(:exist?).with('path/msbuild.exe').and_return(false)
      end

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
