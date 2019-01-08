# frozen_string_literal: true

describe Rake::Funnel::Integration::TeamCity::ServiceMessages do # rubocop:disable RSpec/FilePath
  before do
    allow(Rake::Funnel::Integration::TeamCity).to receive(:running?).and_return(teamcity_running?)
    allow(described_class).to receive(:print)
  end

  context 'when running outside TeamCity' do
    let(:teamcity_running?) { false }

    it 'should not publish messages' do
      described_class.progress_start 'foo'

      expect(described_class).not_to have_received(:print)
    end
  end

  context 'when running inside TeamCity' do
    let(:teamcity_running?) { true }

    describe 'escaping' do
      context 'when publishing messages without special characters' do
        it 'should not escape' do
          described_class.progress_start 'the message'

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart 'the message']\n")
        end
      end

      context 'when publishing messages with special characters' do
        it 'should escape apostrophes' do
          described_class.progress_start "'"

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '|'']\n")
        end

        it 'should escape line feeds' do
          described_class.progress_start "\n"

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '|n']\n")
        end

        it 'should escape carriage returns' do
          described_class.progress_start "\r"

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '|r']\n")
        end

        it 'should escape next lines' do
          described_class.progress_start "\u0085"

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '|x']\n")
        end

        it 'should escape line separators' do
          described_class.progress_start "\u2028"

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '|l']\n")
        end

        it 'should escape paragraph separators' do
          described_class.progress_start "\u2029"

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '|p']\n")
        end

        it 'should escape vertical bars' do
          described_class.progress_start '|'

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '||']\n")
        end

        it 'should escape opening brackets' do
          described_class.progress_start '['

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '|[']\n")
        end

        it 'should escape closing brackets' do
          described_class.progress_start ']'

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '|]']\n")
        end

        it 'should escape all special characters in a string' do
          described_class.progress_start "[\r|\n]"

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressStart '|[|r|||n|]']\n")
        end
      end
    end

    describe 'parameters' do
      context 'when reporting a message without parameters' do
        it 'should print the service message' do
          described_class.enable_service_messages

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[enableServiceMessages]\n")
        end
      end

      context 'when reporting a message with an unnamed parameter' do
        it 'should print the service message' do
          described_class.progress_message 'the message'

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressMessage 'the message']\n")
        end
      end

      context 'when reporting a message with an unnamed non-string parameter' do
        it 'should print the service message' do
          described_class.progress_message 42

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[progressMessage '42']\n")
        end
      end

      context 'when reporting a message with a named parameter' do
        it 'should print the service message' do
          described_class.block_opened(name: 'block name')

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[blockOpened name='block name']\n")
        end
      end

      context 'when reporting a message with multiple named parameters' do
        it 'should print the service message' do
          described_class.test_started(name: 'test name', captureStandardOutput: true)

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[testStarted name='test name' captureStandardOutput='true']\n")
        end
      end

      context 'when reporting a message with Ruby-style named parameters' do
        it 'should print the service message' do
          described_class.test_started(capture_standard_output: true)

          expect(described_class).to \
            have_received(:print)
            .with("##teamcity[testStarted captureStandardOutput='true']\n")
        end
      end
    end
  end
end
