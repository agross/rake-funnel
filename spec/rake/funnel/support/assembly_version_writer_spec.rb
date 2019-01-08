# frozen_string_literal: true

require 'erb'

describe Rake::Funnel::Support::AssemblyVersionWriter do
  describe 'version source' do
    describe 'default' do
      before do
        allow_any_instance_of(described_class).to receive(:create) # rubocop:disable RSpec/AnyInstance
      end

      it 'should create FromVersionFiles with empty args' do
        expect(subject).to have_received(:create).with(:from_version_files, {})
      end
    end

    describe 'custom type' do
      let(:source) { :custom }
      let(:source_args) { { foo: 42 } }

      before do
        allow_any_instance_of(described_class).to receive(:create) # rubocop:disable RSpec/AnyInstance
      end

      subject do
        described_class.new(source, source_args)
      end

      it 'should create type with args' do
        expect(subject).to have_received(:create).with(source, source_args)
      end
    end

    describe 'custom instance' do
      let(:source) do
        [
          {
            source: 'from e.g. gitversion',
            version_info: Rake::Funnel::Support::VersionInfo.new(
              assembly_version: '1',
              assembly_file_version: '1.2',
              assembly_informational_version: '1.2-abc'
            )
          }
        ]
      end

      it 'should succeed' do
        described_class.new(source)
      end
    end
  end

  describe '#write' do
    let(:source) do
      [
        {
          source: 'one',
          version_info: Rake::Funnel::Support::VersionInfo.new(assembly_version: '1',
                                                               assembly_file_version: '1.2',
                                                               assembly_informational_version: '1.2-abc')
        },
        {
          source: 'two',
          version_info: Rake::Funnel::Support::VersionInfo.new(assembly_version: '2',
                                                               assembly_file_version: '2.3',
                                                               assembly_informational_version: '2.3-def')
        }
      ]
    end

    let(:target_path) { double(Proc).as_null_object } # rubocop:disable RSpec/VerifiedDoubles
    let(:languages) { %i(vb cs fs) }

    subject do
      described_class.new(source)
    end

    before do
      allow($stderr).to receive(:print)
    end

    before do
      allow(ERB).to receive(:new).and_call_original
    end

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:write)
    end

    context 'supported languages' do
      before do
        subject.write(target_path, languages)
      end

      it 'should determine target path for each language in source' do
        source.each do |src|
          languages.each do |language|
            expect(target_path).to have_received(:call).with(language, src[:version_info], src[:source])
          end
        end
      end

      it 'should read version info template for languages' do
        languages.each do |language|
          expect(File).to have_received(:read).with(%r{assembly_version/languages/#{language}}).at_least(:once)
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
        expect { subject.write(target_path, languages) }.to \
          raise_error(/Language is not supported: unsupported/)
      end
    end

    describe 'version modification' do
      let(:target_path) do
        proc do |_language, version_info, _source|
          version_info.assembly_informational_version = 'totally custom'
          'file'
        end
      end

      before do
        subject.write(target_path, languages)
      end

      it 'should use modified version info to generate file' do
        expect(File).to \
          have_received(:write)
          .with('file', /AssemblyInformationalVersion\("totally custom"\)/)
          .at_least(:once)
      end
    end
  end
end
