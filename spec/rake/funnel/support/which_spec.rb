# frozen_string_literal: true

require 'tmpdir'

describe Rake::Funnel::Support::Which do
  let(:temp_dir) { Dir.mktmpdir }
  let(:executable_path) { File.join(temp_dir, 'executable.exe') }
  let(:create_entry) { ->(p) { FileUtils.touch(p) } }

  before do
    create_entry.call(executable_path)

    allow(ENV).to receive(:[]).with('PATH').and_return(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe 'executable in PATH' do
    context 'found' do
      it 'should yield executable' do
        expect(described_class.which(File.basename(executable_path))).to eq(executable_path)
      end
    end

    context 'not found' do
      it 'should yield nil' do
        expect(described_class.which('does-not-exist.exe')).to be_nil
      end
    end

    context 'found as directory' do
      let(:create_entry) { ->(p) { FileUtils.mkdir_p(p) } }

      it 'should yield nil' do
        expect(described_class.which('executable.exe')).to be_nil
      end
    end
  end

  describe 'executable in current working directory' do
    context 'found' do
      it 'should yield executable' do
        Dir.chdir(temp_dir) do
          expect(described_class.which(File.basename(executable_path))).to eq(File.basename(executable_path))
        end
      end
    end

    context 'not found' do
      it 'should yield nil' do
        Dir.chdir(temp_dir) do
          expect(described_class.which('does-not-exist.exe')).to be_nil
        end
      end
    end

    context 'found as directory' do
      let(:create_entry) { ->(p) { FileUtils.mkdir_p(p) } }

      it 'should yield nil' do
        expect(described_class.which('executable.exe')).to be_nil
      end
    end
  end
end
