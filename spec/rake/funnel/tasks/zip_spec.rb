require 'tmpdir'

include Rake
include Rake::Funnel::Support

describe Rake::Funnel::Tasks::Zip do
  before {
    CLEAN.clear
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :package }
    its(:source) { should eq([]) }
    its(:target) { should be_nil }
    its(:zip_root) { should be_nil }

    it 'should not add the target file to the files to be cleaned' do
      expect(CLEAN).to be_empty
    end

    describe 'overriding defaults' do
      subject {
        described_class.new do |t|
          t.target = 'something.zip'
        end
      }

      it 'should add the target file to the files to be cleaned' do
        expect(CLEAN).to include(subject.target)
      end
    end
  end

  describe 'execution' do
    let(:source) { %w(bin/1 bin/2 bin/3/4) }
    let(:target) { 'some path/file.zip' }
    let(:zip_root) { nil }

    subject! {
      described_class.new do |t|
        t.source = source
        t.target = target
        t.zip_root = zip_root
      end
    }

    context 'failure' do
      context 'target not defined' do
        let(:target) { nil }

        it 'should fail' do
          expect(lambda { Task[subject.name].invoke }).to raise_error(/Target not defined/)
        end
      end
    end

    context 'success' do
      let(:finder) { double(Finder).as_null_object }
      let(:zip) { double(::Zip::File).as_null_object }
      let(:mtime) { Time.new(2015, 3, 9) }
      let(:zip_entry) { double(::Zip::Entry).as_null_object }

      before {
        allow(finder).to receive(:all_or_default).and_return(source)
        allow(Finder).to receive(:new).and_return(finder)
        allow(RakeFileUtils).to receive(:mkdir_p)
        allow(Rake).to receive(:rake_output_message)
        allow(::Zip::File).to receive(:open).with(target, ::Zip::File::CREATE).and_yield(zip)
      }

      before {
        allow(zip).to receive(:add).and_return(zip_entry)
        allow(File).to receive(:mtime).and_return(mtime)
      }

      before {
        Task[subject.name].invoke
      }

      it 'should create the target directory' do
        expect(RakeFileUtils).to have_received(:mkdir_p).with(File.dirname(target))
      end

      it 'should allow unicode names' do
        expect(::Zip.unicode_names).to eq(true)
      end

      it 'should use best compression' do
        expect(::Zip.default_compression).to eq(Zlib::BEST_COMPRESSION)
      end

      it 'should report the created zip file' do
        expect(Rake).to have_received(:rake_output_message).with("Created #{target}")
      end

      [nil, '', 'some path/inside the zip file'].each do |root|
        context "with '#{root || 'nil'}' zip root" do
          let(:zip_root) { root }

          def build_args
            common_path = finder.all_or_default.common_path

            finder.all_or_default.map do |file|
              zip_path = file.sub(%r|^#{Regexp.escape(common_path)}/|, '')
              zip_path = File.join(zip_root, zip_path) unless zip_root.nil? || zip_root.empty?

              [
                zip_path,
                file
              ]
            end
          end

          it 'should put files below a common path in the zip root' do
            files = build_args

            files.each do |file_args|
              expect(zip).to have_received(:add).with(*file_args)
            end
          end

          it 'should explicitly set the file mtime to work around https://github.com/rubyzip/rubyzip/issues/176' do
            expect(zip_entry).to have_received(:time=).with(mtime).exactly(build_args.length).times
          end
        end
      end
    end
  end
end
