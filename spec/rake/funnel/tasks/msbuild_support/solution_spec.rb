require 'rake/funnel'

include Rake::Funnel
include Rake::Funnel::Tasks::MSBuildSupport

describe Solution do
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
    described_class.new(%W(#{dir}/**/*.sln #{dir}/**/*.??proj), OpenStruct.new(name: 'task name'))
  }

  context 'no solution and project' do
    it 'should fail' do
      expect(lambda { subject.find }).to raise_error(AmbiguousFileError)
    end
  end

  context 'more than one solution' do
    let(:generate) { %w(foo/project1.sln foo/project2.sln) }

    it 'should fail' do
      expect(lambda { subject.find }).to raise_error(AmbiguousFileError)
    end
  end

  context 'more than one project' do
    let(:generate) { %w(foo/project.csproj foo/project.fsproj) }

    it 'should fail' do
      expect(lambda { subject.find }).to raise_error(AmbiguousFileError)
    end
  end

  context 'one solution' do
    let(:generate) { 'foo/project.sln' }

    it 'should find solution' do
      expect(subject.find).to eq(File.join(dir, generate))
    end
  end

  context 'one project' do
    let(:generate) { 'foo/project.fsproj' }

    it 'should find project' do
      expect(subject.find).to eq(File.join(dir, generate))
    end
  end
end
