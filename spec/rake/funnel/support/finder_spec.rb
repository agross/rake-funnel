require 'rake/funnel'

include Rake::Funnel
include Rake::Funnel::Support

describe Finder do
  let(:generate) { [] }

  let!(:dir) {
    tmp = Dir.mktmpdir

    ([] << generate).flatten.each do |g|
      file = "#{tmp}/#{g}"

      FileUtils.mkdir_p(File.dirname(file))
      FileUtils.touch(file)
    end

    tmp
  }

  after { FileUtils.rm_rf dir }

  subject {
    described_class.new(%W(#{dir}/**/*.sln #{dir}/**/*.??proj), OpenStruct.new(name: 'task name'), 'error message')
  }

  describe '#single' do
    context 'no matching files' do
      it 'should fail' do
        expect(lambda { subject.single }).to raise_error(AmbiguousFileError, /error message/)
      end
    end

    context 'more than one matching file' do
      let(:generate) { %w(foo/project1.sln foo/project2.sln) }

      it 'should fail' do
        expect(lambda { subject.single }).to raise_error(AmbiguousFileError, /error message/)
      end
    end

    context 'one matching file' do
      let(:generate) { 'foo/project.sln' }

      it 'should yield match' do
        expect(subject.single).to eq(File.join(dir, generate))
      end
    end
  end

  describe '#single_or_default' do
    context 'no matching files' do
      it 'should yield nil' do
        expect(subject.single_or_default).to be_nil
      end
    end

    context 'more than one matching file' do
      let(:generate) { %w(foo/project1.sln foo/project2.sln) }

      it 'should yield first match' do
        expect(subject.single_or_default).to be_nil
      end
    end

    context 'one matching file' do
      let(:generate) { 'foo/project.sln' }

      it 'should yield match' do
        expect(subject.single_or_default).to eq(File.join(dir, generate))
      end
    end
  end

  describe '#all' do
    context 'no matching files' do
      it 'should fail' do
        expect(lambda { subject.all }).to raise_error(AmbiguousFileError, /error message/)
      end
    end

    context 'more than one matching file' do
      let(:generate) { %w(foo/project1.sln foo/project2.sln) }

      it 'should yield all matches' do
        expect(subject.all).to match_array(generate.map { |file| File.join(dir, file) })
      end
    end

    context 'one matching file' do
      let(:generate) { 'foo/project.sln' }

      it 'should yield all matches' do
        expect(subject.all).to match_array([File.join(dir, generate)])
      end
    end
  end

  describe '#all_or_default' do
    context 'no matching files' do
      it 'should be empty' do
        expect(subject.all_or_default).to be_empty
      end
    end

    context 'more than one matching file' do
      let(:generate) { %w(foo/project1.sln foo/project2.sln) }

      it 'should yield all matches' do
        expect(subject.all_or_default).to match_array(generate.map { |file| File.join(dir, file) })
      end
    end

    context 'one matching file' do
      let(:generate) { 'foo/project.sln' }

      it 'should yield all matches' do
        expect(subject.all_or_default).to match_array([File.join(dir, generate)])
      end
    end
  end
end
