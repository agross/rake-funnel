require 'tmpdir'

include Rake::Funnel::Support

describe Rake::Funnel::Support::Mono do
  before {
    allow(Rake::Win32).to receive(:windows?).and_return(windows?)
  }

  context 'on Windows' do
    let(:windows?) { true }

    it 'should return executable' do
      expect(described_class.invocation('executable.exe')).to eq(%w(executable.exe))
    end

    it 'should return executable with args' do
      expect(described_class.invocation('executable.exe', 'arg1', 'arg2')).to eq(%w(executable.exe arg1 arg2))
    end

    it 'should return array executable with args' do
      expect(described_class.invocation(%w(executable.exe arg1 arg2))).to eq(%w(executable.exe arg1 arg2))
    end

    it 'should reject nil in array' do
      expect(described_class.invocation(%w(executable.exe arg1) << nil)).to eq(%w(executable.exe arg1))
    end

    it 'should reject nil as arg' do
      expect(described_class.invocation('executable.exe', nil)).to eq(%w(executable.exe))
    end
  end

  context 'not on Windows' do
    let(:windows?) { false }

    before {
      allow(Which).to receive(:which)
    }

    before {
      @cmd = described_class.invocation('executable.exe')
    }

    it "should prepend 'mono'" do
      expect(@cmd.first).to eq('mono')
    end

    it 'should resolve executable through which' do
      expect(Which).to have_received(:which).with('executable.exe')
    end

    it 'should support args' do
      expect(described_class.invocation(%w(executable.exe arg1 arg2))).to eq(%w(mono executable.exe arg1 arg2))
    end
  end
end
