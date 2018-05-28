describe Rake::Funnel::Support::Trace do
  before do
    allow($stderr).to receive(:print)
  end

  context 'Rake run with --trace' do
    before do
      allow(Rake.application.options).to receive(:trace).and_return(true)
    end

    it 'should write messages' do
      described_class.message('foo')

      expect($stderr).to have_received(:print).with("foo\n")
    end
  end

  context 'Rake run without --trace' do
    before do
      allow(Rake.application.options).to receive(:trace).and_return(false)
    end

    it 'should not write messages' do
      described_class.message('foo')

      expect($stderr).not_to have_received(:print)
    end
  end
end
