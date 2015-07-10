require 'erb'

include Rake::Funnel::Support

describe Rake::Funnel::Support::AssemblyVersionWriter do
  describe 'version source' do
    describe 'default' do
      before {
        allow_any_instance_of(described_class).to receive(:create)
      }

      it 'should create FromVersionFiles with empty args' do
        expect(subject).to have_received(:create).with(:from_version_files, {})
      end
    end

    describe 'custom type' do
      let(:source) { :custom }
      let(:source_args) { { foo: 42 } }

      before {
        allow_any_instance_of(described_class).to receive(:create)
      }

      subject {
        described_class.new(source, source_args)
      }

      it 'should create type with args' do
        expect(subject).to have_received(:create).with(source, source_args)
      end
    end

    describe 'custom instance' do
      let(:source) {
        [
          {
            source: 'from e.g. gitversion',
            version_info: VersionInfo.new(
              {
                assembly_version: '1',
                assembly_file_version: '1.2',
                assembly_informational_version: '1.2-abc'
              })
          }
        ]
      }

      subject {
        described_class.new(source)
      }

      it 'should succeed' do
        expect(subject).to be
      end
    end
  end

  describe '#write' do
    let(:source) {
      [
        {
          source: 'one',
          version_info: VersionInfo.new(
            {
              assembly_version: '1',
              assembly_file_version: '1.2',
              assembly_informational_version: '1.2-abc'
            })
        },
        {
          source: 'two',
          version_info: VersionInfo.new(
            {
              assembly_version: '2',
              assembly_file_version: '2.3',
              assembly_informational_version: '2.3-def'
            })
        }
      ]
    }

    let(:target_path) { double(Proc).as_null_object }
    let(:languages) { [:vb, :cs, :fs] }

    subject {
      described_class.new(source)
    }

    before {
      allow(Rake).to receive(:rake_output_message)
    }

    before {
      allow(ERB).to receive(:new).and_call_original
    }

    before {
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:write)
    }

    context 'supported languages' do
      before {
        subject.write(target_path, languages)
      }

      it 'should determine target path for each language in source' do
        source.each do |src|
          languages.each do |language|
            expect(target_path).to have_received(:call).with(language, src[:version_info], src[:source])
          end
        end
      end

      it 'should read version info template for languages' do
        languages.each do |language|
          expect(File).to have_received(:read).with(%r|assembly_version/languages/#{language}|).at_least(:once)
        end
      end

      it 'should run templates through ERb' do
        expect(ERB).to have_received(:new).exactly(languages.length * source.length).times
      end

      it 'should write version info file for each language in source' do
        expect(File).to have_received(:write).exactly(languages.length * source.length).times
      end
    end

    context 'unsupported language' do
      let(:languages) { :unsupported }

      it 'should fail' do
        expect { subject.write(target_path, languages) }.to raise_error /Language is not supported: unsupported/
      end
    end

    describe 'version modification' do
      let(:target_path) {
        proc { |_language, version_info, source|
          version_info.assembly_informational_version = 'totally custom'
          'file'
        }
      }

      before {
        subject.write(target_path, languages)
      }

      it 'should use modified version info to generate file' do
        expect(File).to have_received(:write).with('file', /AssemblyInformationalVersion\("totally custom"\)/).at_least(:once)
      end
    end
  end
end
