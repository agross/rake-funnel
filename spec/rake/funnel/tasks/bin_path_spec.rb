include Rake

describe Rake::Funnel::Tasks::BinPath do
  before {
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :bin_path }
    its(:search_pattern) { should eq(%w(tools/* tools/*/bin packages/**/tools)) }
  end

  describe 'execution' do
    let(:default_path) { 'default PATH contents' }
    let(:search_pattern) { %w(foo bar) }

    before {
      allow(ENV).to receive(:[]).with('PATH').and_return(default_path)
      allow(ENV).to receive(:[]=)
      allow(Rake).to receive(:rake_output_message)
    }

    subject {
      described_class.new do |t|
        t.search_pattern = search_pattern
      end
    }

    context 'paths to add' do
      before {
        allow(Dir).to receive(:[]).with(*search_pattern).and_return(search_pattern)
      }

      before {
        Task[subject.name].invoke
      }

      it 'should prepend sorted matching folders to the PATH environment variable' do
        paths = search_pattern.map { |path| File.expand_path(path) }.sort.join(File::PATH_SEPARATOR)

        expect(ENV).to have_received(:[]=).with('PATH',/^#{paths}/)
      end

      it 'should append original PATH environment variable' do
        expect(ENV).to have_received(:[]=).with('PATH', /#{default_path}$/)
      end

      it 'should report added paths' do
        expect(Rake).to have_received(:rake_output_message).with(%r|/foo$|)
        expect(Rake).to have_received(:rake_output_message).with(%r|/bar$|)
      end
    end

    context 'no paths to add' do
      before {
        allow(Dir).to receive(:[]).with(*search_pattern).and_return([])
      }

      before {
        Task[subject.name].invoke
      }

      it 'should not print message' do
        expect(Rake).not_to have_received(:rake_output_message)
      end
    end
  end
end
