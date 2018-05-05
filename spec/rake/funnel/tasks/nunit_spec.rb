describe Rake::Funnel::Tasks::NUnit do # rubocop:disable RSpec/FilePath
  before do
    Rake::Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :test }
    its(:args) { should == {} }
    its(:nunit) { should == 'nunit-console.exe' }
    its(:files) { should == %w(build/specs/**/*.dll build/specs/**/*.exe) }
  end

  describe 'execution' do
    let(:args) { {} }

    let(:mapper) { instance_double(Rake::Funnel::Support::Mapper).as_null_object }
    let(:finder) { instance_double(Rake::Funnel::Support::Finder).as_null_object }

    before do
      allow(subject).to receive(:sh)

      allow(Rake::Funnel::Support::Mapper).to receive(:new).and_return(mapper)
      allow(Rake::Funnel::Support::Finder).to receive(:new).and_return(finder)
      allow(Rake::Funnel::Integration::TeamCity::NUnitPlugin).to receive(:setup)

      allow(Rake::Funnel::Support::Mono).to receive(:invocation).and_wrap_original do |_original_method, *args, &_block|
        args.compact
      end
    end

    before do
      Rake::Task[subject.name].invoke
    end

    it 'should use test assembly finder' do
      expect(finder).to have_received(:all)
    end

    it 'should set up TeamCity plugin' do
      expect(Rake::Funnel::Integration::TeamCity::NUnitPlugin).to have_received(:setup).with(subject.nunit)
    end

    it 'should use NUnit mapper' do
      expect(Rake::Funnel::Support::Mapper).to have_received(:new).with(:NUnit)
    end

    it 'should map arguments' do
      expect(mapper).to have_received(:map).with(args)
    end

    it 'should use mono invocation' do
      expect(Rake::Funnel::Support::Mono).to have_received(:invocation).with(subject.nunit)
    end

    it 'should run with sh' do
      expect(subject).to have_received(:sh)
    end

    context 'with custom NUnit executable' do
      subject do
        described_class.new do |t|
          t.nunit = 'custom nunit.exe'
        end
      end

      its(:nunit) { should == 'custom nunit.exe' }
    end
  end
end
