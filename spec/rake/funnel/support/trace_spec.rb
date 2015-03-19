describe Rake::Funnel::Support::Trace do
  before {
    allow(Rake).to receive(:rake_output_message)
  }

  context 'Rake run with --trace' do
    before {
      allow(Rake.application.options).to receive(:trace).and_return(true)
    }

    it 'should write messages' do
      described_class.message('foo')

      expect(Rake).to have_received(:rake_output_message).with('foo')
    end
  end

  context 'Rake run without --trace' do
    before {
      allow(Rake.application.options).to receive(:trace).and_return(false)
    }

    it 'should not write messages' do
      described_class.message('foo')

      expect(Rake).not_to have_received(:rake_output_message)
    end
  end
end
