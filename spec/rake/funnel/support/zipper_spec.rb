describe Rake::Funnel::Support::Zipper do
  describe '#zip' do
    let(:source) { %w(bin/1 bin/2 bin/3/4) }

    context 'failure' do
      context 'target not defined' do
        let(:target) { nil }

        it 'should fail' do
          expect { described_class.zip(source, target) }.to raise_error(/Target not defined/)
        end
      end
    end

    context 'success' do
      let(:target) { 'some path/file.zip' }
      let(:zip_root) { nil }
      let(:zip) { instance_double(::Zip::File).as_null_object }
      let(:mtime) { Time.new(2015, 3, 9) }
      let(:zip_entry) { double(::Zip::Entry).as_null_object } # rubocop:disable RSpec/VerifiedDoubles

      before do
        allow(RakeFileUtils).to receive(:mkdir_p)
      end

      before do
        allow(::Zip::File).to receive(:open).with(target, ::Zip::File::CREATE).and_yield(zip)
        allow(zip).to receive(:add).and_return(zip_entry)
        allow(File).to receive(:mtime).and_return(mtime)
      end

      before do
        described_class.zip(source, target, zip_root)
      end

      it 'should create the target directory' do
        expect(RakeFileUtils).to have_received(:mkdir_p).with(File.dirname(target))
      end

      describe 'configuration' do
        it 'should allow unicode names' do
          expect(::Zip.unicode_names).to eq(true)
        end

        it 'should use best compression' do
          expect(::Zip.default_compression).to eq(Zlib::BEST_COMPRESSION)
        end
      end

      describe 'work-around for https://github.com/rubyzip/rubyzip/issues/176' do
        it 'should explicitly set the file mtime' do
          expect(zip_entry).to have_received(:time=).with(mtime).exactly(source.length).times
        end
      end

      describe 'common path' do
        it 'should remove the common path from the source' do
          expect(zip).not_to have_received(:add).with(/#{source.common_path}/, anything)
        end
      end

      describe 'zip root' do
        [nil, '', 'some path/inside the zip file'].each do |root|
          context "with '#{root || 'nil'}'" do
            let(:zip_root) { root }

            it "should put files below #{root.nil? || root.empty? ? 'the root' : "'#{root}'"}" do
              expect(zip).to have_received(:add).with(/^#{root}/, anything).exactly(source.length).times
            end
          end
        end
      end
    end
  end
end
