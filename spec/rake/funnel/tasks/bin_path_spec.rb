require 'rake'
require 'rake/funnel'

describe Rake::Funnel::Tasks::BinPath do

  before {
    Rake::Task.clear
    expect(subject).to be
  }

  describe 'defaults' do
    its(:name) { should == :bin_path }
    its(:pattern) { is_expected.to match_array(%w(tools/* tools/*/bin)) }
  end

  describe 'execution' do
    before {
      allow(ENV).to receive(:[]).with('PATH').and_return('default PATH contents')
      allow(ENV).to receive(:[]=)
    }

    it 'should prepend matching folders to the PATH environment variable' do
      subject.pattern = %w(foo bar)

      allow(Dir).to receive(:[]).with(*subject.pattern).and_return(subject.pattern)

      Rake::Task[:bin_path].invoke

      paths = subject.pattern.map { |path| File.expand_path(path) } << ENV['PATH']

      expect(ENV).to have_received(:[]=).with('PATH', paths.join(File::PATH_SEPARATOR))
    end
  end
end
