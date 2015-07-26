describe Rake::Funnel::Integration::TeamCity do
  describe 'runner detection' do
    before {
      allow(ENV).to receive(:include?).with(described_class::PROJECT_ENV_VAR).and_return(teamcity_running?)
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
        module Rake
          module TeamCityApplication
          end
        end

        expect(described_class.rake_runner?).to eq(true)
      end
    end
  end

  describe '#with_java_runtime' do
    let(:original_path) { 'original path environment variable contents' }
    let(:jre) { nil }

    before {
      allow(ENV).to receive(:[]=)

      allow(ENV).to receive(:[]).with('PATH').and_return(original_path)

      allow(ENV).to receive(:include?).with(described_class::JRE_ENV_VAR).and_return(!jre.nil?)
      allow(ENV).to receive(:[]).with(described_class::JRE_ENV_VAR).and_return(jre)
    }

    context 'without block' do
      it 'should not modify environment variables' do
        described_class.with_java_runtime

        expect(ENV).not_to have_received(:[]=)
      end
    end

    context 'with block' do
      context 'Java runtime environment variable does not exists' do
        let(:jre) { nil }

        it 'should yield to block' do
          expect { |b| described_class.with_java_runtime(&b) }.to yield_with_no_args
        end

        it 'should not modify path' do
          described_class.with_java_runtime {}

          expect(ENV).not_to have_received(:[]=).with('PATH')
        end
      end

      context 'Java runtime environment variable exists' do
        let(:jre) { 'path/to/JRE' }

        it 'should yield to block' do
          expect { |b| described_class.with_java_runtime(&b) }.to yield_with_no_args
        end

        it 'should add JRE to path' do
          described_class.with_java_runtime {}

          expect(ENV).to have_received(:[]=).with('PATH', /#{original_path}.#{jre}/)
        end

        it 'should reset path' do
          described_class.with_java_runtime {}

          expect(ENV).to have_received(:[]=).with('PATH', original_path)
        end

        context 'block error' do
          it 'should reset path' do
            expect { described_class.with_java_runtime { fail 'with some error' } }.to raise_error(/with some error/)

            expect(ENV).to have_received(:[]=).with('PATH', original_path)
          end
        end
      end
    end
  end
end
