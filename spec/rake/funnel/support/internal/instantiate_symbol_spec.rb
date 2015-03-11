describe Rake::Funnel::Support::InstantiateSymbol do
  module Creatable
    class One
    end

    class Two
    end

    class Three
    end
  end

  class ExplicitModuleDefinition
    include Rake::Funnel::Support::InstantiateSymbol
    instantiate Creatable

    class Nested
    end
  end

  class ImplicitModuleDefinition
    include Rake::Funnel::Support::InstantiateSymbol

    class Nested
    end
  end

  describe 'module methods' do
    subject {
      ExplicitModuleDefinition.new
    }

    describe 'instance methods' do
      it 'should not be public' do
        expect(subject).not_to respond_to(:create)
        expect(subject).not_to respond_to(:available)
      end
    end

    describe 'class methods' do
      it 'should not be public' do
        expect(subject.class).not_to respond_to(:instantiate)
      end
    end
  end

  describe 'inspection' do
    context 'implicit module' do
      subject {
        ImplicitModuleDefinition.new
      }

      it 'should yield constants in self' do
        expect(subject.send(:available)).to eq([:ClassMethods, :Nested])
      end
    end

    context 'explicit module' do
      subject {
        ExplicitModuleDefinition.new
      }

      it 'should yield sorted constants in module' do
        expect(subject.send(:available)).to eq([:One, :Three, :Two])
      end
    end

    context 'multiple uses' do
      subject {
        [
          ExplicitModuleDefinition.new,
          ImplicitModuleDefinition.new
        ]
      }

      it 'should not overlap' do
        first = subject[0].send(:available)
        second = subject[1].send(:available)

        expect(first).not_to include(second)
      end
    end
  end

  describe 'instantiation' do
    subject {
      ExplicitModuleDefinition.new
    }

    context 'with instance' do
      it 'should return instance' do
        instance = Object.new

        expect(subject.send(:create, instance)).to eq(instance)
      end
    end


    context 'with nil' do
      it 'should return nil' do
        expect(subject.send(:create, nil)).to eq(nil)
      end
    end

    context 'symbol not defined' do
      it 'should fail' do
        expect { subject.send(:create, :does_not_exist) }.to raise_error 'Unknown type to instantiate: :does_not_exist. Available types are: [:One, :Three, :Two]'
      end
    end

    context 'instantiation fails' do
      class WillFail
        include Rake::Funnel::Support::InstantiateSymbol

        class Failure
          def initialize
            raise "BAM!"
          end
        end
      end

      subject {
        WillFail.new
      }

      it 'should fail' do
        expect { subject.send(:create, :Failure) }.to raise_error "BAM!"
      end
    end

    context 'instantiation succeeds' do
      it 'should return instance' do
        expect(subject.send(:create, :One)).to be_an_instance_of(Creatable::One)
      end
    end

    describe 'args' do
      module CreatableWithArgs
        class None
          def initialize
          end
        end

        class Single
          def initialize(arg)
          end
        end

        class Multiple
          def initialize(arg1, arg2)
          end
        end
      end

      class WithArgs
        include Rake::Funnel::Support::InstantiateSymbol
        instantiate CreatableWithArgs
      end

      subject {
        WithArgs.new
      }

      context 'no argument' do
        it 'should not pass arg' do
          expect(subject.send(:create, :None)).to be_an_instance_of(CreatableWithArgs::None)
        end
      end

      context 'single argument' do
        it 'should pass arg' do
          expect(subject.send(:create, :Single, 1)).to be_an_instance_of(CreatableWithArgs::Single)
        end
      end

      context 'multiple argument' do
        it 'should pass args' do
          expect(subject.send(:create, :Multiple, 1, 2)).to be_an_instance_of(CreatableWithArgs::Multiple)
        end
      end
    end
  end
end
