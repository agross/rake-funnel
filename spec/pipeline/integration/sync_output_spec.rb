require 'pipeline'

describe Pipeline::Integration::SyncOutput do
  before {
    $stdout.stub(:sync=)
    $stderr.stub(:sync=)

    subject.should be
  }

  it 'should immediately flush stdout' do
    expect($stdout).to have_received(:sync=).with(true)
  end

  it 'should immediately flush stderr' do
    expect($stdout).to have_received(:sync=).with(true)
  end
end
