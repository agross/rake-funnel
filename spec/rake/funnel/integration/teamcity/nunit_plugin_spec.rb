# rubocop:disable RSpec/FilePath

describe Rake::Funnel::Integration::TeamCity::NUnitPlugin do
  before do
    allow(ENV).to receive(:[]).with(described_class::ENV_VAR).and_return(env_var)
    allow(Rake::Funnel::Support::Which).to receive(:which).and_return(which)
    allow(Dir).to receive(:glob).and_return([])
    allow(RakeFileUtils).to receive(:mkdir_p)
    allow(Rake).to receive(:rake_output_message)
  end

  before do
    allow(Rake::Funnel::Support::BinaryVersionReader).to receive(:read_from)
      .with(which).and_return(nunit_version)
  end

  describe 'success' do
    let(:env_var) { '/path/to/nunit plugins/nunit' }
    let(:addin_dlls) { [env_var + 'addin.dll'] }
    let(:which) { 'path/to/nunit-console.exe' }
    let(:nunit_version) { Rake::Funnel::Support::VersionInfo.new(file_version: '1.2.3.4') }
    let(:plugin_version) { nunit_version.file_version.split('.').take(3).join('.') }

    before do
      allow(Dir).to receive(:glob).and_return(addin_dlls)
      allow(RakeFileUtils).to receive(:cp)
    end

    before do
      described_class.setup('nunit-console.exe')
    end

    it 'should create addin directory' do
      expect(RakeFileUtils).to have_received(:mkdir_p).with(File.join(File.dirname(which), 'addins'))
    end

    it 'should enumerate addin files' do
      expect(Dir).to have_received(:glob).with(/#{Regexp.escape("#{env_var}-#{plugin_version}\.*")}$/)
    end

    it 'should copy the addin from TeamCity to NUnit' do
      expect(RakeFileUtils).to \
        have_received(:cp).with(addin_dlls,
                                File.join(File.dirname(which), 'addins'),
                                preserve: true)
    end

    it 'should report that the addin is installed' do
      expect(Rake).to \
        have_received(:rake_output_message)
        .with("Installing TeamCity NUnit addin for version #{plugin_version} in #{which}")
    end

    context 'Windows-style path in environment variable',
            skip: ('Windows Registry not available' unless defined?(::Win32::Registry)) do
      let(:env_var) { 'C:\path\to\nunit plugins\nunit-' }

      it 'should convert path to Ruby-style' do
        expect(Dir).to have_received(:glob).with(%r{^C:/path/to/nunit plugins/nunit-})
      end
    end
  end

  describe 'failures' do
    let(:env_var) { nil }
    let(:which) { nil }
    let(:nunit_version) { Rake::Funnel::Support::VersionInfo.new }

    before do
      described_class.setup('nunit-console.exe')
    end

    context 'TeamCity plugin path not in environment' do
      let(:env_var) { nil }

      it 'should skip reading the version' do
        expect(Rake::Funnel::Support::BinaryVersionReader).not_to have_received(:read_from)
      end
    end

    context 'NUnit executable not found' do
      let(:env_var) { '/path/to/nunit plugins/nunit' }
      let(:which) { nil }

      it 'should skip reading the version' do
        expect(Rake::Funnel::Support::BinaryVersionReader).not_to have_received(:read_from)
      end
    end

    context 'NUnit executable without version' do
      let(:env_var) { '/path/to/nunit plugins/nunit' }
      let(:which) { 'path/to/nunit-console.exe' }

      it 'should report that the version could not be read' do
        expect(Rake).to \
          have_received(:rake_output_message)
          .with("Could read version from NUnit executable in #{which}")
      end

      it 'should skip' do
        expect(Dir).not_to have_received(:glob)
      end
    end

    context 'plugin for NUnit version not available' do
      let(:env_var) { '/path/to/nunit plugins/nunit' }
      let(:which) { 'path/to/nunit-console.exe' }
      let(:nunit_version) { Rake::Funnel::Support::VersionInfo.new(file_version: '1.2.3.4') }

      it 'should report that the addin version is not available' do
        expect(Rake).to \
          have_received(:rake_output_message)
          .with(/Could not find TeamCity NUnit addin for version 1\.2\.3 in .*#{env_var}$/)
      end

      it 'should skip' do
        expect(RakeFileUtils).not_to have_received(:mkdir_p)
      end
    end
  end
end
