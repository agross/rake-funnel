require 'rake/funnel'

include Rake::Funnel::Integration::TeamCity

describe ServiceMessages do
  let(:original_project) { ENV['TEAMCITY_PROJECT_NAME'] }

  before {
    ENV.delete 'TEAMCITY_PROJECT_NAME'

    allow($stdout).to receive(:puts)
  }

  after {
    ENV['TEAMCITY_PROJECT_NAME'] = original_project
  }

  context 'when running outside TeamCity' do
    it 'should not publish messages' do
      ServiceMessages.progress_start 'foo'

      expect($stdout).not_to have_received(:puts)
    end
  end

  context 'when running inside TeamCity' do
    before { ENV['TEAMCITY_PROJECT_NAME'] = 'foo' }

    describe 'escaping' do
      context 'when publishing messages without special characters' do
        it 'should not escape' do
          ServiceMessages.progress_start "the message"

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart 'the message']")
        end
      end

      context 'when publishing messages with special characters' do
        it 'should escape apostrophes' do
          ServiceMessages.progress_start "'"

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '|'']")
        end

        it 'should escape line feeds' do
          ServiceMessages.progress_start "\n"

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '|n']")
        end

        it 'should escape carriage returns' do
          ServiceMessages.progress_start "\r"

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '|r']")
        end

        it 'should escape next lines' do
          ServiceMessages.progress_start "\u0085"

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '|x']")
        end

        it 'should escape line separators' do
          ServiceMessages.progress_start "\u2028"

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '|l']")
        end

        it 'should escape paragraph separators' do
          ServiceMessages.progress_start "\u2029"

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '|p']")
        end

        it 'should escape vertical bars' do
          ServiceMessages.progress_start '|'

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '||']")
        end

        it 'should escape opening brackets' do
          ServiceMessages.progress_start '['

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '|[']")
        end

        it 'should escape closing brackets' do
          ServiceMessages.progress_start ']'

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '|]']")
        end

        it 'should escape all special characters in a string' do
          ServiceMessages.progress_start "[\r|\n]"

          expect($stdout).to have_received(:puts).with("##teamcity[progressStart '|[|r|||n|]']")
        end
      end
    end

    describe 'parameters' do
      context 'when reporting a message without parameters' do
        it 'should print the service message' do
          ServiceMessages.enable_service_messages

          expect($stdout).to have_received(:puts).with('##teamcity[enableServiceMessages]')
        end
      end

      context 'when reporting a message with an unnamed parameter' do
        it 'should print the service message' do
          ServiceMessages.progress_message 'the message'

          expect($stdout).to have_received(:puts).with("##teamcity[progressMessage 'the message']")
        end
      end

      context 'when reporting a message with a named parameter' do
        it 'should print the service message' do
          ServiceMessages.block_opened({ :name => 'block name' })

          expect($stdout).to have_received(:puts).with("##teamcity[blockOpened name='block name']")
        end
      end

      context 'when reporting a message with multiple named parameters' do
        it 'should print the service message' do
          ServiceMessages.test_started ({ :name => 'test name', :captureStandardOutput => true })

          expect($stdout).to have_received(:puts).with("##teamcity[testStarted name='test name' captureStandardOutput='true']")
        end
      end

      context 'when reporting a message with Ruby-style named parameters' do
        it 'should print the service message' do
          ServiceMessages.test_started ({ :capture_standard_output => true })

          expect($stdout).to have_received(:puts).with("##teamcity[testStarted captureStandardOutput='true']")
        end
      end
    end
  end
end
