require 'rake'
require 'rake/clean'
require 'rake/funnel'
require 'tmpdir'

describe Rake::Funnel::Tasks::Zip do
  before {
    CLEAN.clear
    Rake::Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :package }
    its(:files) { should eq([]) }
    its(:destination) { should be_nil }
    its(:zip_root) { should be_nil }

    it 'should not add the destination file to the files to be cleaned' do
      expect(CLEAN).to be_empty
    end

    describe 'overriding defaults' do
      subject {
        described_class.new do |t|
          t.destination = 'something.zip'
        end
      }

      it 'should add the destination file to the files to be cleaned' do
        expect(CLEAN).to include(subject.destination)
      end
    end
  end

  describe 'execution' do
    let(:files) { %w(bin/1 bin/2 bin/3/4) }
    let(:destination) { 'some path/file.zip' }
    let(:zip_root) { nil }

    let(:zip) { double(::Zip::File).as_null_object }

    before {
      allow(FileUtils).to receive(:mkdir_p)
      allow(Rake).to receive(:rake_output_message)
      allow(::Zip::File).to receive(:open).with(destination, ::Zip::File::CREATE).and_yield(zip)
    }

    subject! {
      described_class.new do |t|
        t.files = files
        t.destination = destination
        t.zip_root = zip_root
      end
    }

    before {
      Rake::Task[subject.name].invoke
    }

    it 'should create the destination directory' do
      expect(FileUtils).to have_received(:mkdir_p).with(File.dirname(destination))
    end

    it 'should allow unicode names' do
      expect(::Zip.unicode_names).to eq(true)
    end

    it 'should use best compression' do
      expect(::Zip.default_compression).to eq(Zlib::BEST_COMPRESSION)
    end

    it 'should report the created zip file' do
      expect(Rake).to have_received(:rake_output_message).with("Created #{destination}")
    end

    [nil, '', 'some path/inside the zip file'].each do |root|
      context "with '#{root || 'nil'}' zip root" do
        let(:zip_root) { root }

        def build_args
          common_path = subject.files.common_path

          subject.files.map do |file|
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
      end
    end
  end
end
