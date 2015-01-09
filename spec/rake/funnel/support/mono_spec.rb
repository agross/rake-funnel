require 'rake/funnel'
require 'tmpdir'

describe Rake::Funnel::Support::Mono do
  before {
    allow(Rake::Win32).to receive(:windows?).and_return(windows?)
  }

  context 'when running on Windows' do
    let(:windows?) { true }

    it 'should return executable' do
      expect(described_class.invocation('executable.exe')).to eq('executable.exe')
    end

    it 'should return executable with args' do
      expect(described_class.invocation('executable.exe', 'arg1', 'arg2')).to eq(%w(executable.exe arg1 arg2))
    end

    it 'should return array executable with args' do
      expect(described_class.invocation(%w(executable.exe arg1 arg2))).to eq(%w(executable.exe arg1 arg2))
    end
  end

  context 'when not running on Windows' do
    let(:windows?) { false }
    let(:temp_dir) { Dir.mktmpdir }
    let(:executable_path) { File.join(temp_dir, 'executable.exe') }

    before {
      FileUtils.touch(executable_path)

      allow(ENV).to receive(:[]).with('PATH').and_return(temp_dir)
    }

    after {
      FileUtils.rm_rf(temp_dir)
    }

    it "should prepend 'mono'" do
      expect(described_class.invocation('executable.exe')[0]).to eq('mono')
    end

    it 'should resolve executable from PATH' do
      expect(described_class.invocation('executable.exe')[1]).to eq(executable_path)
    end

    it 'should resolve executable from current working directory' do
      Dir.chdir(temp_dir) do
        expect(described_class.invocation('executable.exe')[1]).to eq('executable.exe')
      end
    end

    it 'should support args' do
      expect(described_class.invocation(%w(executable.exe arg1 arg2))).to include('arg1', 'arg2')
    end
  end
end
