describe Rake::Funnel::Support::Patch do
  describe 'without definition' do
    it 'should be applicable' do
      subject.apply!
    end

    it 'should be revertable' do
      subject.revert!
    end

    it 'should be applicable and revertable' do
      subject.apply!.revert!
    end
  end

  describe 'with definition' do
    subject do
      described_class.new do |p|
        p.setup do
          output.print 'setup'
          42
        end

        p.reset do |memo|
          output.print memo
        end
      end
    end

    let(:output) { double.as_null_object }

    context 'when applying the patch' do
      let!(:ret) { subject.apply! }

      it 'should execute the setup' do
        expect(output).to have_received(:print).with('setup')
      end

      it 'should return self' do
        expect(ret).to eq(subject)
      end
    end

    context 'when reverting the patch' do
      let!(:ret) do
        subject.apply!
        subject.revert!
      end

      it 'should execute the reset' do
        expect(output).to have_received(:print).with(42)
      end

      it 'should return self' do
        expect(ret).to eq(subject)
      end
    end

    context 'when reverting an unapplied patch' do
      before { subject.revert! }

      it 'should not execute the reset' do
        expect(output).not_to have_received(:print).with(42)
      end
    end

    context 'when applying twice' do
      before do
        subject.apply!
        subject.apply!
      end

      it 'should execute the setup once' do
        expect(output).to have_received(:print).with('setup').once
      end
    end

    context 'when reverting twice' do
      before do
        subject.apply!
        subject.revert!
        subject.revert!
      end

      it 'should execute the revert once' do
        expect(output).to have_received(:print).with(42).once
      end
    end

    describe 'context' do
      let(:context) { 42 }

      subject do
        described_class.new(context) do |p|
          p.setup do |context|
            output.print context
          end
        end
      end

      before { subject.apply!.revert! }

      it 'should be accessible from within the patch definition' do
        expect(output).to have_received(:print).with(42)
      end
    end
  end
end
