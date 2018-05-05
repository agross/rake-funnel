require 'ostruct'

describe Rake::Funnel::Support::MSBuild::BuildTool do # rubocop:disable RSpec/FilePath
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

    context 'mono not installed' do
      before do
        allow(Open3).to receive(:capture2).with('mono', '--version').and_raise(Errno::ENOENT)
      end

      it 'fails' do
        expect { described_class.find }.to raise_error('mono is not installed')
      end
    end

    context 'mono installed' do
      before do
        allow(Open3).to receive(:capture2).with('mono', '--version').and_return(mono_version)
      end

      context 'mono fails' do
        let(:mono_version) do
          [
            'mono crashed',
            OpenStruct.new(success?: false)
          ]
        end

        it 'should find nothing' do
          expect { described_class.find }.to raise_error(/^Could not determine mono version:/)
        end
      end

      context 'mono < 5.0' do
        let(:mono_version) do
          [
            'Mono JIT compiler version 4.8.1 (mono-4.8.0-branch/22a39d7 Fri Apr  7 12:00:08 EDT 2017)',
            OpenStruct.new(success?: true)
          ]
        end

        it 'should find xbuild' do
          expect(described_class.find).to eq('xbuild')
        end
      end

      context 'mono >= 5.0' do
        let(:mono_version) do
          [
            'Mono JIT compiler version 5.0.0.100 (2017-02/9667aa6 Fri May  5 09:12:57 EDT 2017)',
            OpenStruct.new(success?: true)
          ]
        end

        it 'should find msbuild' do
          expect(described_class.find).to eq('msbuild')
        end
      end
    end
  end
end
