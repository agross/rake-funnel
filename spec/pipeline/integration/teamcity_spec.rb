require 'pipeline'

include Pipeline::Integration

describe TeamCity do
  let(:original_project) { ENV['TEAMCITY_PROJECT_NAME'] }

  before {
    ENV.delete 'TEAMCITY_PROJECT_NAME'
  }

  after {
    ENV['TEAMCITY_PROJECT_NAME'] = original_project
  }

  context 'when running outside TeamCity' do
    it 'should detect' do
      expect(TeamCity.running?).to eq(false)
    end

    it "should not detect TeamCity's rake runner" do
      expect(TeamCity.rake_runner?).to eq(false)
    end

    it 'should not publish messages' do
      expect($stdout).not_to receive(:puts)

      TeamCity.progress_start 'foo'
    end
  end

  context 'when running inside TeamCity' do
    before { ENV['TEAMCITY_PROJECT_NAME'] = 'foo' }

    it 'should detect' do
      expect(TeamCity.running?).to eq(true)
    end

    it "should detect TeamCity's rake runner" do
      module ::Rake
        module TeamCityApplication
        end
      end

      expect(TeamCity.rake_runner?).to eq(true)
    end

    describe 'service messages' do
      describe 'escaping' do
        context 'when publishing messages with special characters' do
          it 'should escape apostrophes' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '|'']")
            TeamCity.progress_start "'"
          end

          it 'should escape line feeds' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '|n']")
            TeamCity.progress_start "\n"
          end

          it 'should escape carriage returns' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '|r']")
            TeamCity.progress_start "\r"
          end

          it 'should escape next lines' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '|x']")
            TeamCity.progress_start "\u0085"
          end

          it 'should escape line separators' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '|l']")
            TeamCity.progress_start "\u2028"
          end

          it 'should escape paragraph separators' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '|p']")
            TeamCity.progress_start "\u2029"
          end

          it 'should escape vertical bars' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '||']")
            TeamCity.progress_start '|'
          end

          it 'should escape opening brackets' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '|[']")
            TeamCity.progress_start '['
          end

          it 'should escape closing brackets' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '|]']")
            TeamCity.progress_start ']'
          end

          it 'should escape all special characters in a string' do
            expect($stdout).to receive(:puts).with("##teamcity[progressStart '|[|r|||n|]']")
            TeamCity.progress_start "[\r|\n]"
          end
        end
      end

      describe 'messages' do
        context 'when reporting a message without parameters' do
          it 'should print the service message' do
            expect($stdout).to receive(:puts).with('##teamcity[enableServiceMessages]')
            TeamCity.enable_service_messages
          end
        end

        context 'when reporting a message with an unnamed parameter' do
          it 'should print the service message' do
            expect($stdout).to receive(:puts).with("##teamcity[progressMessage 'the message']")
            TeamCity.progress_message 'the message'
          end
        end

        context 'when reporting a message with a named parameter' do
          it 'should print the service message' do
            expect($stdout).to receive(:puts).with("##teamcity[blockOpened name='block name']")
            TeamCity.block_opened({ :name => 'block name' })
          end
        end

        context 'when reporting a message with multiple named parameters' do
          it 'should print the service message' do
            expect($stdout).to receive(:puts).with("##teamcity[testStarted name='test name' captureStandardOutput='true']")
            TeamCity.test_started ({ :name => 'test name', :captureStandardOutput => true})
          end
        end
      end
    end
  end
end
