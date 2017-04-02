include Rake

describe Rake::Funnel::Tasks::BinPath do
  before do
    Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :bin_path }
    its(:search_pattern) { should eq(%w(tools/* tools/*/bin packages/**/tools)) }
  end

  describe 'execution' do
    let(:default_path) { 'default PATH contents' }
    let(:search_pattern) { %w(foo bar not-a-directory) }
    let(:directories) do
      search_pattern.first(2)
                    .map { |path| File.expand_path(path) }
                    .sort
                    .join(File::PATH_SEPARATOR)
    end
    let(:path_modifier) { nil }

    before do
      allow(ENV).to receive(:[]).with('PATH').and_return(default_path)
      allow(ENV).to receive(:[]=)
      allow(Rake).to receive(:rake_output_message)
    end

    subject do
      described_class.new do |t|
        t.search_pattern = search_pattern
        t.path_modifier = path_modifier unless path_modifier.nil?
      end
    end

    context 'paths to add' do
      before do
        allow(Dir).to receive(:[]).with(*search_pattern).and_return(search_pattern)
        allow(File).to receive(:directory?).and_return(true)
        allow(File).to receive(:directory?).with(search_pattern.last).and_return(false)
      end

      before do
        Task[subject.name].invoke
      end

      it 'should prepend sorted matching folders to the PATH environment variable' do
        expect(ENV).to have_received(:[]=).with('PATH', /^#{directories}/)
      end

      it 'should reject files' do
        expect(ENV).not_to have_received(:[]=).with('PATH', /#{search_pattern.last}/)
      end

      it 'should append original PATH environment variable' do
        expect(ENV).to have_received(:[]=).with('PATH', /#{default_path}$/)
      end

      it 'should report added paths' do
        expect(Rake).to have_received(:rake_output_message).with(%r{/foo$})
        expect(Rake).to have_received(:rake_output_message).with(%r{/bar$})
      end

      describe 'path modifier' do
        context 'adding paths' do
          let(:path_modifier) { proc { |paths| paths.push('added path') } }

          it 'adds extra paths' do
            expect(ENV).to have_received(:[]=).with('PATH', /added path/)
          end

          it 'retains other paths' do
            expect(ENV).to have_received(:[]=).with('PATH', /foo/)
            expect(ENV).to have_received(:[]=).with('PATH', /bar/)
          end
        end

        context 'rejecting paths' do
          let(:path_modifier) { proc { |paths| paths.reject { |p| p =~ /foo/ } } }

          it 'removes matching paths' do
            expect(ENV).not_to have_received(:[]=).with('PATH', /foo/)
          end

          it 'retains non-matching paths' do
            expect(ENV).to have_received(:[]=).with('PATH', /bar/)
          end
        end
      end
    end

    context 'no paths to add' do
      before do
        allow(Dir).to receive(:[]).with(*search_pattern).and_return([])
      end

      before do
        Task[subject.name].invoke
      end

      it 'should not print message' do
        expect(Rake).not_to have_received(:rake_output_message)
      end

      it 'should not set environment variable' do
        expect(ENV).not_to have_received(:[]=).with('PATH')
      end
    end
  end
end
