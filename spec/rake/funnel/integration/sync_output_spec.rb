describe Rake::Funnel::Integration::SyncOutput do
  context 'stream supports sync mode' do
    before do
      allow($stdout).to receive(:sync=)
      allow($stderr).to receive(:sync=)
    end

    subject! { described_class.new }

    it 'should immediately flush $stdout' do
      expect($stdout).to have_received(:sync=).with(true)
    end

    it 'should immediately flush $stderr' do
      expect($stderr).to have_received(:sync=).with(true)
    end
  end

  context 'stream does not support sync mode' do
    before do
      allow($stdout).to receive(:sync=).and_raise('$stdout.sync not supported')
      allow($stderr).to receive(:sync=).and_raise('$stderr.sync not supported')

      allow(Rake).to receive(:rake_output_message)
    end

    subject! { described_class.new }

    it 'should log the error for $stdout' do
      expect(Rake).to have_received(:rake_output_message).with(/Failed.*\$stdout/)
    end

    it 'should log the error for $stderr' do
      expect(Rake).to have_received(:rake_output_message).with(/Failed.*\$stderr/)
    end
  end
end
