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
      TeamCity.running?.should == false
    end

    it 'should not publish messages' do
      $stdout.should_not_receive(:puts)

      TeamCity.progress_start 'foo'
    end
  end

  context 'when running inside TeamCity' do
    before { ENV['TEAMCITY_PROJECT_NAME'] = 'foo' }

    it 'should detect' do
      TeamCity.running?.should == true
    end

    describe 'service messages' do
      describe 'escaping' do
        context 'when publishing messages with special characters' do
          it 'should escape apostrophes' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '|'']")
            TeamCity.progress_start "'"
          end

          it 'should escape line feeds' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '|n']")
            TeamCity.progress_start "\n"
          end

          it 'should escape carriage returns' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '|r']")
            TeamCity.progress_start "\r"
          end

          it 'should escape next lines' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '|x']")
            TeamCity.progress_start "\u0085"
          end

          it 'should escape line separators' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '|l']")
            TeamCity.progress_start "\u2028"
          end

          it 'should escape paragraph separators' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '|p']")
            TeamCity.progress_start "\u2029"
          end

          it 'should escape vertical bars' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '||']")
            TeamCity.progress_start '|'
          end

          it 'should escape opening brackets' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '|[']")
            TeamCity.progress_start '['
          end

          it 'should escape closing brackets' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '|]']")
            TeamCity.progress_start ']'
          end

          it 'should escape all special characters in a string' do
            $stdout.should_receive(:puts).with("##teamcity[progressStart '|[|r|||n|]']")
            TeamCity.progress_start "[\r|\n]"
          end
        end
      end

      describe 'messages' do
        context 'when reporting a message without parameters' do
          it 'should print the service message' do
            $stdout.should_receive(:puts).with('##teamcity[enableServiceMessages]')
            TeamCity.enable_service_messages
          end
        end

        context 'when reporting a message with an unnamed parameter' do
          it 'should print the service message' do
            $stdout.should_receive(:puts).with("##teamcity[progressMessage 'the message']")
            TeamCity.progress_message 'the message'
          end
        end

        context 'when reporting a message with a named parameter' do
          it 'should print the service message' do
            $stdout.should_receive(:puts).with("##teamcity[blockOpened name='block name']")
            TeamCity.block_opened({ :name => 'block name' })
          end
        end

        context 'when reporting a message with multiple named parameters' do
          it 'should print the service message' do
            $stdout.should_receive(:puts).with("##teamcity[testStarted name='test name' captureStandardOutput='true']")
            TeamCity.test_started ({ :name => 'test name', :captureStandardOutput => true})
          end
        end
      end
    end
  end
end
