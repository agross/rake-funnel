# frozen_string_literal: true

describe Rake::Funnel::Tasks::Paket do
  before do
    Rake::Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :paket }
    its(:paket) { should == '.paket/paket.exe' }
    its(:paket_args) { should == 'restore' }
    its(:bootstrapper) { should == '.paket/paket.bootstrapper.exe' }
    its(:bootstrapper_args) { should be_nil }
  end

  describe 'execution' do
    before do
      allow(subject).to receive(:sh)
      allow(Rake::Funnel::Support::Mono).to receive(:invocation).and_wrap_original do |_original_method, *args, &_block|
        args.compact
      end
    end

    context 'overriding defaults' do
      subject do
        described_class.new do |t|
          t.bootstrapper = 'custom bootstrapper.exe'
          t.bootstrapper_args = %w(arg1 arg2)
          t.paket = 'custom paket.exe'
          t.paket_args = %w(arg1 arg2)
        end
      end

      before do
        allow(File).to receive(:exist?).and_return(false)
        allow(subject).to receive(:sh)
      end

      before do
        Rake::Task[subject.name].invoke
      end

      it 'should use custom bootstrapper' do
        expect(subject).to have_received(:sh).with(subject.bootstrapper, subject.bootstrapper_args)
      end

      it 'should use custom paket' do
        expect(subject).to have_received(:sh).with(subject.paket, subject.paket_args)
      end
    end

    describe 'mono invocation' do
      before do
        Rake::Task[subject.name].invoke
      end

      it 'should use mono invocation for bootstrapper' do
        expect(Rake::Funnel::Support::Mono).to have_received(:invocation)
          .with(subject.bootstrapper,
                subject.bootstrapper_args)
      end

      it 'should use mono invocation for paket' do
        expect(Rake::Funnel::Support::Mono).to have_received(:invocation)
          .with(subject.paket,
                subject.paket_args)
      end
    end

    describe 'optional download' do
      before do
        allow(File).to receive(:exist?).with(subject.paket).and_return(paket_exists)
        allow(subject).to receive(:sh).with(subject.bootstrapper)
      end

      context 'success' do
        before do
          Rake::Task[subject.name].invoke
        end

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

          it 'should run paket' do
            expect(subject).to have_received(:sh).with(subject.paket, subject.paket_args)
          end
        end
      end

      context 'failure' do
        context 'paket.exe exists' do
          let(:paket_exists) { true }

          context 'paket failed' do
            before do
              allow(subject).to receive(:sh).with(subject.paket, anything).and_raise
            end

            it 'should fail' do
              expect { Rake::Task[subject.name].invoke }.to raise_error(RuntimeError)
            end
          end
        end

        context 'paket.exe does not exist' do
          let(:paket_exists) { false }

          context 'bootstrapper failed' do
            before do
              allow(subject).to receive(:sh).with(subject.bootstrapper).and_raise(RuntimeError)
            end

            it 'should not run paket' do
              begin
                Rake::Task[subject.name].invoke
              rescue RuntimeError
                nil
              end

              expect(subject).not_to have_received(:sh).with(subject.paket, subject.paket_args)
            end

            it 'should fail' do
              expect { Rake::Task[subject.name].invoke }.to raise_error(RuntimeError)
            end
          end
        end
      end
    end
  end
end
