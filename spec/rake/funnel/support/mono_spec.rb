require 'tmpdir'

include Rake::Funnel::Support

describe Rake::Funnel::Support::Mono do
  shared_examples 'on Windows' do
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

  before do
    allow(Rake::Win32).to receive(:windows?).and_return(windows?)
  end

  context 'on Windows' do
    context 'plain Windows' do
      let(:windows?) { true }

      it_behaves_like 'on Windows'
    end

    context 'Windows Subsystem for Linux' do
      let(:windows?) { false }

      before do
        allow(File).to receive(:readable?).with('/proc/version').and_return(true)
        allow(File).to receive(:read).with('/proc/version').and_return('Microsoft')
      end

      it_behaves_like 'on Windows'
    end
  end

  context 'not on Windows' do
    let(:windows?) { false }

    before do
      allow(File).to receive(:readable?).with('/proc/version').and_return(false)
      allow(Which).to receive(:which)
    end

    before do
      @cmd = described_class.invocation('executable.exe')
    end

    it "should prepend 'mono'" do
      expect(@cmd.first).to eq('mono') # rubocop:disable RSpec/InstanceVariable
    end

    it 'should resolve executable through which' do
      expect(Which).to have_received(:which).with('executable.exe')
    end

    it 'should support args' do
      expect(described_class.invocation(%w(executable.exe arg1 arg2))).to eq(%w(mono executable.exe arg1 arg2))
    end
  end
end
