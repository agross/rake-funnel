require 'rake/funnel'

describe Rake::Funnel::Support::Mono do
  before {
    allow(Rake::Win32).to receive(:windows?).and_return(windows?)
  }

  context 'when running on Windows' do
    let(:windows?) { true }

    it 'should return executable' do
      expect(described_class.invocation('executable')).to eq('executable')
    end

    it 'should return executable with args' do
      expect(described_class.invocation('executable', 'arg1', 'arg2')).to eq(%w(executable arg1 arg2))
    end

    it 'should return array executable with args' do
      expect(described_class.invocation(%w(executable arg1 arg2))).to eq(%w(executable arg1 arg2))
    end
  end

  context 'when not running on Windows' do
    let(:windows?) { false }

    it "should prepend 'mono' to simple executable" do
      expect(described_class.invocation('executable')).to eq(%w(mono executable))
    end

    it "should prepend 'mono' to executable with args" do
      expect(described_class.invocation('executable', 'arg1', 'arg2')).to eq(%w(mono executable arg1 arg2))
    end

    it "should prepend 'mono' to array executable with args" do
      expect(described_class.invocation(%w(executable arg1 arg2))).to eq(%w(mono executable arg1 arg2))
    end
  end
end
