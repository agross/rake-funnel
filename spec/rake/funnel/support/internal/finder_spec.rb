require 'tmpdir'

include Rake::Funnel

describe Rake::Funnel::Support::Finder do
  let(:pattern) { %W(#{temp_dir}/**/*.sln #{temp_dir}/**/*.??proj) }
  let(:generate) { [] }
  let(:temp_dir) { Dir.mktmpdir }

  before {
    Dir.chdir(temp_dir) do
      ([] << generate).flatten.each do |file|
        FileUtils.mkdir_p(File.dirname(file))
        FileUtils.touch(file)
      end
    end
  }

  after {
    FileUtils.rm_rf(temp_dir)
  }

  subject {
    described_class.new(pattern, OpenStruct.new(name: 'task name'), 'error message')
  }

  def map_temp(*files)
    mapped = files.map { |f| File.join(temp_dir, f) }
    return mapped.first if mapped.one?
    mapped
  end

  describe 'enumerable' do
    let(:generate) { %w(1 2 3 4) }
    let(:pattern) { '**/*' }

    it { is_expected.to be_kind_of(Enumerable) }
    it { is_expected.to respond_to(:each) }

    it 'should yield enumerator' do
      expect(subject.each).to be_kind_of(Enumerator)
    end

    it 'should support enumerable methods' do
      Dir.chdir(temp_dir) do
        items = subject.map { |x| x }
        expect(subject.all_or_default).to match_array(items)
      end
    end
  end

  describe 'patterns' do
    let(:generate) { %w(1 2 3 4) }

    context 'single pattern' do
      let(:pattern) { '**/*' }

      it 'should yield' do
        Dir.chdir(temp_dir) do
          expect(subject.all_or_default).to match_array(generate)
        end
      end
    end

    context 'pattern list' do
      let(:pattern) { %w(**/*) }

      it 'should yield' do
        Dir.chdir(temp_dir) do
          expect(subject.all_or_default).to match_array(generate)
        end
      end
    end

    context 'Rake::FileList' do
      let(:pattern) { FileList['**/*'] }

      it 'should yield' do
        Dir.chdir(temp_dir) do
          expect(subject.all_or_default).to match_array(generate)
        end
      end
    end

    context 'patterns generating multiple matches per file' do
      let(:pattern) { %w(**/* **/*) }

      it 'should remove duplicates' do
        Dir.chdir(temp_dir) do
          expect(subject.all_or_default).to match_array(generate)
        end
      end
    end
  end

  describe 'source is evaluated lazily' do
    let(:pattern) { FileList['*.example'] }

    it 'should detect new files' do
      expect(subject.all_or_default).to be_empty

      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          FileUtils.touch('new file.example')

          expect(subject.all).to include('new file.example')
        end
      end
    end
  end

  describe '#single' do
    context 'no matching files' do
      it 'should fail' do
        Dir.chdir(temp_dir) do
          expect { subject.single }.to raise_error(AmbiguousFileError, /error message/)
        end
      end
    end

    context 'more than one matching file' do
      let(:generate) { %w(foo/project1.sln foo/project2.sln) }

      it 'should fail' do
        Dir.chdir(temp_dir) do
          expect { subject.single }.to raise_error(AmbiguousFileError, /error message/)
        end
      end
    end

    context 'one matching file' do
      let(:generate) { 'foo/project.sln' }

      it 'should yield match' do
        Dir.chdir(temp_dir) do
          expect(subject.single).to eq(map_temp(generate))
        end
      end
    end
  end

  describe '#single_or_default' do
    context 'no matching files' do
      it 'should yield nil' do
        Dir.chdir(temp_dir) do
          expect(subject.single_or_default).to be_nil
        end
      end
    end

    context 'more than one matching file' do
      let(:generate) { %w(foo/project1.sln foo/project2.sln) }

      it 'should yield first match' do
        Dir.chdir(temp_dir) do
          expect(subject.single_or_default).to be_nil
        end
      end
    end

    context 'one matching file' do
      let(:generate) { 'foo/project.sln' }

      it 'should yield match' do
        Dir.chdir(temp_dir) do
          expect(subject.single_or_default).to eq(map_temp(generate))
        end
      end
    end
  end

  describe '#all' do
    context 'no matching files' do
      it 'should fail' do
        expect { subject.all }.to raise_error(AmbiguousFileError, /error message/)
      end
    end

    context 'more than one matching file' do
      let(:generate) { %w(foo/project1.sln foo/project2.sln) }

      it 'should yield all matches' do
        Dir.chdir(temp_dir) do
          expect(subject.all).to match_array(map_temp(*generate))
        end
      end
    end

    context 'one matching file' do
      let(:generate) { 'foo/project.sln' }

      it 'should yield all matches' do
        Dir.chdir(temp_dir) do
          expect(subject.all).to match_array(map_temp(generate))
        end
      end
    end
  end

  describe '#all_or_default' do
    context 'no matching files' do
      it 'should be empty' do
        Dir.chdir(temp_dir) do
          expect(subject.all_or_default).to be_empty
        end
      end
    end

    context 'more than one matching file' do
      let(:generate) { %w(foo/project1.sln foo/project2.sln) }

      it 'should yield all matches' do
        Dir.chdir(temp_dir) do
          expect(subject.all_or_default).to match_array(map_temp(*generate))
        end
      end
    end

    context 'one matching file' do
      let(:generate) { 'foo/project.sln' }

      it 'should yield all matches' do
        Dir.chdir(temp_dir) do
          expect(subject.all_or_default).to match_array(map_temp(generate))
        end
      end
    end
  end
end
