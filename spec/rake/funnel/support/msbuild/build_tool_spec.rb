# frozen_string_literal: true

require 'ostruct'

describe Rake::Funnel::Support::MSBuild::BuildTool do # rubocop:disable RSpec/FilePath
  context 'vswhere' do
    let(:vswhere_args) do
      %w(vswhere.exe -products * -latest -requires Microsoft.Component.MSBuild -property installationPath)
    end

    before do
      allow(described_class).to receive(:require).with('win32/registry').and_raise(LoadError)
      allow(Open3).to receive(:capture2).with('mono', any_args).and_raise(Errno::ENOENT)
    end

    context 'not installed' do
      before do
        allow(Open3).to receive(:capture2).with(*vswhere_args).and_raise(Errno::ENOENT)
      end

      it 'finds nothing' do
        expect { described_class.find }.to raise_error('No compatible MSBuild build tool was found')
      end
    end

    context 'installed' do
      before do
        allow(Open3).to receive(:capture2).with(*vswhere_args).and_return(vswhere_path)
      end

      context 'fails' do
        let(:vswhere_path) do
          [
            'vswhere crashed',
            OpenStruct.new(success?: false)
          ]
        end

        before do
          allow($stderr).to receive(:print)
        end

        it 'finds nothing' do
          expect { described_class.find }.to raise_error('No compatible MSBuild build tool was found')
        end

        it 'warns about the crash' do
          described_class.find rescue nil # rubocop:disable Style/RescueModifier
          expect($stderr).to have_received(:print).with(/^vswhere failed:/)
        end
      end

      describe 'MSBuild executable' do
        let(:vswhere_path) do
          [
            'c:\path',
            OpenStruct.new(success?: true)
          ]
        end

        before do
          allow(Dir).to receive(:[]).with('c:/path/MSBuild/*/Bin/MSBuild.exe')
                                    .and_return(['c:/path/msbuild.exe'])
        end

        context 'exists' do
          before do
            allow(File).to receive(:file?).with('c:/path/msbuild.exe').and_return(true)
          end

          it 'finds msbuild.exe' do
            expect(described_class.find).to eq('c:/path/msbuild.exe')
          end
        end

        context 'does not exist' do
          before do
            allow(File).to receive(:exist?).with('c:/path/msbuild.exe').and_return(false)
          end

          it 'finds nothing' do
            expect { described_class.find }.to raise_error('No compatible MSBuild build tool was found')
          end
        end
      end
    end
  end

  context 'Registry',
          skip: ('Windows Registry not available on this platform' unless defined?(::Win32::Registry)) do
    before do
      allow(::Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).and_yield('MSBuildToolsPath' => 'path')
    end

    it 'searches the registry for known MSBuild versions' do
      described_class.find rescue nil # rubocop:disable Style/RescueModifier
      expect(::Win32::Registry::HKEY_LOCAL_MACHINE).to have_received(:open).at_least(:once)
    end

    context 'Registry key not found' do
      before do
        allow(::Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).and_raise(::Win32::Registry::Error.new(3))
      end

      it 'finds nothing' do
        expect { described_class.find }.to raise_error('No compatible MSBuild build tool was found')
      end
    end

    describe 'MSBuild executable' do
      context 'exists' do
        before do
          allow(File).to receive(:exist?).with('path/msbuild.exe').and_return(true)
        end

        it 'finds msbuild.exe' do
          expect(described_class.find).to eq('path/msbuild.exe')
        end
      end

      context 'does not exist' do
        before do
          allow(File).to receive(:exist?).with('path/msbuild.exe').and_return(false)
        end

        it 'finds nothing' do
          expect { described_class.find }.to raise_error('No compatible MSBuild build tool was found')
        end
      end
    end
  end

  context 'mono' do
    before do
      allow(described_class).to receive(:require).with('win32/registry').and_raise(LoadError)
      allow(Open3).to receive(:capture2).with('vswhere.exe', any_args).and_raise(Errno::ENOENT)
    end

    context 'not installed' do
      before do
        allow(Open3).to receive(:capture2).with('mono', '--version').and_raise(Errno::ENOENT)
      end

      it 'finds nothing' do
        expect { described_class.find }.to raise_error('No compatible MSBuild build tool was found')
      end
    end

    context 'installed' do
      before do
        allow(Open3).to receive(:capture2).with('mono', '--version').and_return(mono_version)
      end

      context 'fails' do
        let(:mono_version) do
          [
            'mono crashed',
            OpenStruct.new(success?: false)
          ]
        end

        before do
          allow($stderr).to receive(:print)
        end

        it 'finds nothing' do
          expect { described_class.find }.to raise_error('No compatible MSBuild build tool was found')
        end

        it 'warns about the crash' do
          described_class.find rescue nil # rubocop:disable Style/RescueModifier
          expect($stderr).to have_received(:print).with(/^Could not determine mono version:/)
        end
      end

      context 'mono < 5.0' do
        let(:mono_version) do
          [
            'Mono JIT compiler version 4.8.1 (mono-4.8.0-branch/22a39d7 Fri Apr  7 12:00:08 EDT 2017)',
            OpenStruct.new(success?: true)
          ]
        end

        it 'finds xbuild' do
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

        it 'finds msbuild' do
          expect(described_class.find).to eq('msbuild')
        end
      end
    end
  end
end
