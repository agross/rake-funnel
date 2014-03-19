require 'rake'
require 'pipeline'

describe Pipeline::Tasks::BinPath do

  before {
    Rake::Task.clear
    subject.should_not be_nil
  }

  describe 'defaults' do
    its(:name) { should == :bin_path }
    its(:pattern) { should =~ ['tools/*', 'tools/*/bin'] }
  end

  describe 'execution' do
    before {
      ENV.stub(:[]).with('PATH').and_return('default PATH contents')
      ENV.stub(:[]=)
    }

    it 'should prepend matching folders to the PATH environment variable' do
      subject.pattern = ['foo', 'bar']

      Dir.stub(:[]).with(*subject.pattern).and_return(subject.pattern)

      Rake::Task[:bin_path].invoke

      paths = subject.pattern.map { |path| File.expand_path(path) } << ENV['PATH']

      expect(ENV).to have_received(:[]=).with('PATH', paths.join(File::PATH_SEPARATOR))
    end
  end
end
