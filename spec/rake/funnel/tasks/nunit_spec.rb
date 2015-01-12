require 'rake/funnel'

include Rake::Funnel
include Rake::Funnel::Integration
include Rake::Funnel::Tasks

describe NUnit do
  before {
    Rake::Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :test }
    its(:args) { should == {} }
    its(:nunit) { should == 'nunit-console.exe' }
    its(:files) { should == %w(build/specs/**/*.dll build/specs/**/*.exe) }
  end

  describe 'overriding defaults' do
    context 'when NUnit executable is specified' do
      subject {
        described_class.new do |t|
          t.nunit = 'custom nunit.exe'
        end
      }

      its(:nunit) { should == 'custom nunit.exe' }
    end
  end

  describe 'execution' do
    let(:args) { {} }

    let(:mapper) { double(Support::Mapper).as_null_object }
    let(:finder) { double(Support::Finder).as_null_object }

    before {
      allow(subject).to receive(:sh)

      allow(Support::Mapper).to receive(:new).and_return(mapper)
      allow(Support::Finder).to receive(:new).and_return(finder)
      allow(TeamCity::NUnitPlugin).to receive(:setup)

      allow(Support::Mono).to receive(:invocation).and_wrap_original do |original_method, *args, &block|
        args.compact
      end
    }

    before {
      Rake::Task[subject.name].invoke
    }

    it 'should use test assembly finder' do
      expect(finder).to have_received(:all)
    end

    it 'should set up TeamCity plugin' do
      expect(TeamCity::NUnitPlugin).to have_received(:setup).with(subject.nunit)
    end

    it 'should use NUnit mapper' do
      expect(Support::Mapper).to have_received(:new).with(:NUnit)
    end

    it 'should map arguments' do
      expect(mapper).to have_received(:map).with(args)
    end

    it 'should use mono invocation' do
      expect(Support::Mono).to have_received(:invocation).with(subject.nunit)
    end

    it 'should run with sh' do
      expect(subject).to have_received(:sh)
    end
  end
end
