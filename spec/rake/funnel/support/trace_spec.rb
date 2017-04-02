describe Rake::Funnel::Support::Trace do
  before do
    allow(Rake).to receive(:rake_output_message)
  end

  context 'Rake run with --trace' do
    before do
      allow(Rake.application.options).to receive(:trace).and_return(true)
    end

    it 'should write messages' do
      described_class.message('foo')

      expect(Rake).to have_received(:rake_output_message).with('foo')
    end
  end

  context 'Rake run without --trace' do
    before do
      allow(Rake.application.options).to receive(:trace).and_return(false)
    end

    it 'should not write messages' do
      described_class.message('foo')

      expect(Rake).not_to have_received(:rake_output_message)
    end
  end
end
