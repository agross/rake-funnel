include Rake
include Rake::Funnel::Support

describe Rake::Funnel::Tasks::Paket do
  before {
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :paket }
    its(:paket) { should == '.paket/paket.exe' }
    its(:paket_args) { should == 'restore' }
    its(:bootstrapper) { should == '.paket/paket.bootstrapper.exe' }
    its(:bootstrapper_args) { should be_nil }
  end

  describe 'execution' do
    before {
      allow(subject).to receive(:sh)
      allow(Mono).to receive(:invocation).and_wrap_original do |_original_method, *args, &_block|
        args.compact
      end
    }

    context 'overriding defaults' do
      subject {
        described_class.new do |t|
          t.bootstrapper = 'custom bootstrapper.exe'
          t.bootstrapper_args = %w(arg1 arg2)
          t.paket = 'custom paket.exe'
          t.paket_args = %w(arg1 arg2)
        end
      }

      before {
        allow(File).to receive(:exist?).and_return(false)
        allow(subject).to receive(:sh)
      }

      before {
        Task[subject.name].invoke
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
        Task[subject.name].invoke
      }

      it 'should use mono invocation for bootstrapper' do
        expect(Mono).to have_received(:invocation).with(subject.bootstrapper, subject.bootstrapper_args)
      end

      it 'should use mono invocation for paket' do
        expect(Mono).to have_received(:invocation).with(subject.paket, subject.paket_args)
      end
    end

    describe 'optional download' do
      before {
        allow(File).to receive(:exist?).with(subject.paket).and_return(paket_exists)
        allow(subject).to receive(:sh).with(subject.bootstrapper)
      }

      context 'success' do
        before {
          Task[subject.name].invoke
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

          it 'should run paket' do
            expect(subject).to have_received(:sh).with(subject.paket, subject.paket_args)
          end
        end
      end

      context 'failure' do
        context 'paket.exe exists' do
          let(:paket_exists) { true }

          context 'paket failed' do
            before {
              allow(subject).to receive(:sh).with(subject.paket, anything).and_raise
            }

            it 'should fail' do
              expect { Task[subject.name].invoke }.to raise_error
            end
          end
        end

        context 'paket.exe does not exist' do
          let(:paket_exists) { false }

          context 'bootstrapper failed' do
            before {
              allow(subject).to receive(:sh).with(subject.bootstrapper).and_raise
            }

            it 'should not run paket' do
              Task[subject.name].invoke rescue nil

              expect(subject).not_to have_received(:sh).with(subject.paket, subject.paket_args)
            end

            it 'should fail' do
              expect { Task[subject.name].invoke }.to raise_error
            end
          end
        end
      end
    end
  end
end
