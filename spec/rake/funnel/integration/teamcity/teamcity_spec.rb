describe Rake::Funnel::Integration::TeamCity do
  before {
    allow(ENV).to receive(:include?).with(described_class::ENV_VAR).and_return(teamcity_running?)
  }

  context 'when running outside TeamCity' do
    let(:teamcity_running?) { false }

    it 'should not detect TeamCity' do
      expect(described_class.running?).to eq(false)
    end

    it "should not detect TeamCity's rake runner" do
      expect(described_class.rake_runner?).to eq(false)
    end
  end

  context 'when running inside TeamCity' do
    let(:teamcity_running?) { true }

    it 'should detect TeamCity' do
      expect(described_class.running?).to eq(true)
    end

    it "should detect TeamCity's rake runner" do
      module ::Rake
        module TeamCityApplication
        end
      end

      expect(described_class.rake_runner?).to eq(true)
    end
  end
end
