include Rake

describe Rake::Funnel::Tasks::BinPath do
  before {
    Task.clear
    expect(subject).to be
  }

  describe 'defaults' do
    its(:name) { should == :bin_path }
    its(:search_pattern) { is_expected.to match_array(%w(tools/* tools/*/bin packages/**/tools)) }
  end

  describe 'execution' do
    before {
      allow(ENV).to receive(:[]).with('PATH').and_return('default PATH contents')
      allow(ENV).to receive(:[]=)
      allow(Rake).to receive(:rake_output_message)
    }

    before {
      subject.search_pattern = %w(foo bar)

      allow(Dir).to receive(:[]).with(*subject.search_pattern).and_return(subject.search_pattern)

      Task[:bin_path].invoke
    }

    it 'should prepend sorted matching folders to the PATH environment variable' do
      paths = subject.search_pattern.sort.map { |path| File.expand_path(path) } << ENV['PATH']

      expect(ENV).to have_received(:[]=).with('PATH', paths.join(File::PATH_SEPARATOR))
    end

    it 'should report added paths' do
      expect(Rake).to have_received(:rake_output_message).with(%r|/foo$|)
      expect(Rake).to have_received(:rake_output_message).with(%r|/bar$|)
    end
  end
end
