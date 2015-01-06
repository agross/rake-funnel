require 'rake/funnel'

describe Rake::Funnel::Integration::TeamCity do
  let(:original_project) { ENV['TEAMCITY_PROJECT_NAME'] }

  before {
    ENV.delete 'TEAMCITY_PROJECT_NAME'
  }

  after {
    ENV['TEAMCITY_PROJECT_NAME'] = original_project
  }

  context 'when running outside TeamCity' do
    it 'should not detect TeamCity' do
      expect(Rake::Funnel::Integration::TeamCity.running?).to eq(false)
    end

    it "should not detect TeamCity's rake runner" do
      expect(Rake::Funnel::Integration::TeamCity.rake_runner?).to eq(false)
    end
  end

  context 'when running inside TeamCity' do
    before { ENV['TEAMCITY_PROJECT_NAME'] = 'foo' }

    it 'should detect TeamCity' do
      expect(Rake::Funnel::Integration::TeamCity.running?).to eq(true)
    end

    it "should detect TeamCity's rake runner" do
      module ::Rake
        module TeamCityApplication
        end
      end

      expect(Rake::Funnel::Integration::TeamCity.rake_runner?).to eq(true)
    end
  end
end
