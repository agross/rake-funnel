require 'rake/funnel'

describe Rake::Funnel::Integration::TeamCity::NUnitPlugin do
  let(:env_var) { nil }
  let(:which) { nil }
  let(:nunit_exe_contents) { nil }

  before {
    allow(ENV).to receive(:[]).with('teamcity.dotnet.nunitaddin').and_return(env_var)
    allow(Rake::Funnel::Support::Which).to receive(:which).and_return(which)
    allow(File).to receive(:read).with(which).and_return(nunit_exe_contents)
    allow(Dir).to receive(:glob).and_return([])
    allow(RakeFileUtils).to receive(:mkdir_p)
    allow(Rake).to receive(:rake_output_message)
  }

  def binary_version(*version_parts)
    version = version_parts.map { |p| p.to_s + "\0" }.join(".\0")
    "F\0i\0l\0e\0V\0e\0r\0s\0i\0o\0n" + "\0" * 3 + version + "\0" * 3
  end

  describe 'success' do
    let(:env_var) { 'path/to/nunit plugins/nunit' }
    let(:addin_dlls) { [env_var + 'addin.dll'] }
    let(:which) { 'path/to/nunit-console.exe' }
    let(:nunit_exe_contents) { "binary #{binary_version(1, 2, 3, 4)} binary" }

    before {
      allow(Dir).to receive(:glob).and_return(addin_dlls)
      allow(RakeFileUtils).to receive(:cp)
    }

    before {
      described_class.setup('nunit-console.exe')
    }

    it 'should create addin directory' do
      expect(RakeFileUtils).to have_received(:mkdir_p).with(File.join(File.dirname(which), 'addins'))
    end

    it 'should enumerate addin files' do
      expect(Dir).to have_received(:glob).with("#{env_var}-1.2.3.*")
    end

    it 'should copy the addin from TeamCity to NUnit' do
      expect(RakeFileUtils).to have_received(:cp).with(addin_dlls, File.join(File.dirname(which), 'addins'))
    end

    it 'should report that the addin is installed' do
      expect(Rake).to have_received(:rake_output_message).with("Installing TeamCity NUnit addin for version 1.2.3 in #{which}")
    end

    context 'Windows-style path in environment variable', platform: :win32 do
      let(:env_var) { 'C:\path\to\nunit plugins\nunit-' }

      it 'should convert path to Ruby-style' do
        expect(Dir).to have_received(:glob).with(%r|^C:/path/to/nunit plugins/nunit-|)
      end
    end
  end

  describe 'failures' do
    before {
      described_class.setup('nunit-console.exe')
    }

    context 'TeamCity plugin path not in environment' do
      let(:env_var) { nil }

      it 'should skip' do
        expect(File).to_not have_received(:read)
      end
    end

    context 'NUnit executable not found' do
      let(:env_var) { 'path/to/nunit plugins/nunit' }
      let(:which) { nil }

      it 'should skip' do
        expect(File).to_not have_received(:read)
      end
    end

    context 'NUnit executable without version' do
      let(:env_var) { 'path/to/nunit plugins/nunit' }
      let(:which) { 'path/to/nunit-console.exe' }
      let(:nunit_exe_contents) { 'version number not available ' }

      it 'should report that the version could not be read' do
        expect(Rake).to have_received(:rake_output_message).with("Could read version from NUnit executable in #{which}")
      end

      it 'should skip' do
        expect(Dir).not_to have_received(:glob)
      end
    end

    context 'plugin for NUnit version not available' do
      let(:env_var) { 'path/to/nunit plugins/nunit' }
      let(:which) { 'path/to/nunit-console.exe' }
      let(:nunit_exe_contents) { binary_version(1, 2, 3, 4) }

      it 'should report that the addin version is not available' do
        expect(Rake).to have_received(:rake_output_message).with("Could not find TeamCity NUnit addin for version 1.2.3 in #{env_var}")
      end

      it 'should skip' do
        expect(RakeFileUtils).not_to have_received(:mkdir_p)
      end
    end
  end
end
