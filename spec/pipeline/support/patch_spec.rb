require 'pipeline'

describe Pipeline::Support::Patch do
  subject {
    Pipeline::Support::Patch.new do |p|
      p.setup do
        output.puts 'setup'
        42
      end

      p.reset do |memo|
        output.puts memo
      end
    end
  }

  let(:output) { double.as_null_object }

  context 'when applying the patch' do
    before { @ret = subject.apply! }

    it 'should execute the setup' do
      expect(output).to have_received(:puts).with('setup')
    end

    it 'should return self' do
      @ret.should eq(subject)
    end
  end

  context 'when reverting the patch' do
    before {
      subject.apply!
      @ret = subject.revert!
    }

    it 'should execute the reset' do
      expect(output).to have_received(:puts).with(42)
    end

    it 'should return self' do
      @ret.should eq(subject)
    end
  end

  context 'when reverting an unapplied patch' do
    before { subject.revert! }

    it 'should not execute the reset' do
      expect(output).to_not have_received(:puts).with(42)
    end
  end

  context 'when applying twice' do
    before {
      subject.apply!
      subject.apply!
    }

    it 'should execute the setup once' do
      expect(output).to have_received(:puts).with('setup').once
    end
  end

  context 'when reverting twice' do
    before {
      subject.apply!
      subject.revert!
      subject.revert!
    }

    it 'should execute the revert once' do
      expect(output).to have_received(:puts).with(42).once
    end
  end
end
