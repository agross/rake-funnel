describe Rake::Funnel::Integration::SyncOutput do
  before {
    allow($stdout).to receive(:sync=)
    allow($stderr).to receive(:sync=)

    expect(subject).to be
  }

  it 'should immediately flush stdout' do
    expect($stdout).to have_received(:sync=).with(true)
  end

  it 'should immediately flush stderr' do
    expect($stdout).to have_received(:sync=).with(true)
  end
end
