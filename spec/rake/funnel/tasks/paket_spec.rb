require 'rake/funnel'

include Rake::Funnel::Tasks

describe Paket do
  before {
    Rake::Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :paket }
    its(:paket) { should == '.paket/paket.exe' }
    its(:paket_args) { should == 'restore' }
    its(:bootstrapper) { should == '.paket/paket.bootstrapper.exe' }
    its(:bootstrapper_args) { should == nil }
  end

  describe 'overriding defaults' do
    context 'when bootstrapper executable is specified' do
      subject {
        described_class.new do |t|
          t.bootstrapper = 'custom bootstrapper.exe'
        end
      }

      its(:bootstrapper) { should == 'custom bootstrapper.exe' }
    end

    context 'when bootstrapper args are specified' do
      subject {
        described_class.new do |t|
          t.bootstrapper_args = %w(arg1 arg2)
        end
      }

      its(:bootstrapper_args) { should == %w(arg1 arg2) }
      end

    context 'when paket executable is specified' do
      subject {
        described_class.new do |t|
          t.paket = 'custom paket.exe'
        end
      }

      its(:paket) { should == 'custom paket.exe' }
    end

    context 'when paket args are specified' do
      subject {
        described_class.new do |t|
          t.paket_args = %w(arg1 arg2)
        end
      }

      its(:paket_args) { should == %w(arg1 arg2) }
    end
  end

  describe 'execution' do
    before {
      allow(subject).to receive(:sh)
      allow(Rake::Funnel::Support::Mono).to receive(:invocation).and_wrap_original do |original_method, *args, &block|
        args.compact
      end
    }

    context 'with overridden defaults' do
      subject {
        described_class.new do |t|
          t.bootstrapper = 'custom bootstrapper.exe'
          t.bootstrapper_args = %w(arg1 arg2)
          t.paket = 'custom paket.exe'
          t.paket_args = %w(arg1 arg2)
        end
      }

      before {
        allow(File).to receive(:exist?).with(subject.paket).and_return(false)
        allow(subject).to receive(:sh)
      }

      before {
        Rake::Task[subject.name].invoke
      }

      it 'should use custom bootstrapper' do
        expect(subject).to have_received(:sh).with(subject.bootstrapper, subject.bootstrapper_args)
      end

      it 'should use custom paket' do
        expect(subject).to have_received(:sh).with(subject.paket, subject.paket_args)
      end
    end

    describe 'mono invocation' do
      before {
        Rake::Task[subject.name].invoke
      }

      it 'should use mono invocation for bootstrapper' do
        expect(Rake::Funnel::Support::Mono).to have_received(:invocation).with(subject.bootstrapper, subject.bootstrapper_args)
      end

      it 'should use mono invocation for paket' do
        expect(Rake::Funnel::Support::Mono).to have_received(:invocation).with(subject.paket, subject.paket_args)
      end
    end

    describe 'optional download' do
      let(:fail_bootstrapper) { false }

      before {
        allow(File).to receive(:exist?).with(subject.paket).and_return(paket_exists)
      }

      before {
        allow(subject).to receive(:sh).with(subject.bootstrapper).and_raise if fail_bootstrapper
      }

      before {
        begin
          Rake::Task[subject.name].invoke
        rescue => e
          @raised_error = e
        end
      }

      context 'paket.exe exists' do
        let(:paket_exists) { true }

        it 'should not run bootstrapper' do
          expect(subject).not_to have_received(:sh).with(subject.bootstrapper)
        end

        it 'should run paket' do
          expect(subject).to have_received(:sh).with(subject.paket, subject.paket_args)
        end
      end

      context 'paket.exe does not exist' do
        let(:paket_exists) { false }

        it 'should run bootstrapper' do
          expect(subject).to have_received(:sh).with(subject.bootstrapper)
        end

        context 'bootstrapper succeeded' do
          it 'should run paket' do
            expect(subject).to have_received(:sh).with(subject.paket, subject.paket_args)
          end
        end

        context 'bootstrapper failed' do
          let(:fail_bootstrapper) { true }

          it 'should not run paket' do
            expect(subject).not_to have_received(:sh).with(subject.paket, subject.paket_args)
          end

          it 'should fail' do
            expect(@raised_error).to be
          end
        end
      end
    end
  end
end
