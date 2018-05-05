describe Rake::Funnel::Support::InstantiateSymbol do # rubocop:disable RSpec/FilePath
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

  module SnakeCase
    class SnakeCase
    end

    class Snake_Case # rubocop:disable Naming/ClassAndModuleCamelCase
    end
  end

  class SnakeCaseModuleDefinition
    include Rake::Funnel::Support::InstantiateSymbol

    instantiate SnakeCase
  end

  describe 'module methods' do
    subject do
      ExplicitModuleDefinition.new
    end

    describe 'instance methods' do
      it 'should not be public' do
        expect(subject).not_to respond_to(:create)
        expect(subject).not_to respond_to(:available)
        expect(subject).not_to respond_to(:mod)
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
      subject do
        ImplicitModuleDefinition.new
      end

      it 'should yield constants in self' do
        expect(subject.send(:available)).to eq(%i(ClassMethods Nested))
      end
    end

    context 'explicit module' do
      subject do
        ExplicitModuleDefinition.new
      end

      it 'should yield sorted constants in module' do
        expect(subject.send(:available)).to eq(%i(One Three Two))
      end
    end

    context 'multiple uses' do
      subject do
        [
          ExplicitModuleDefinition.new,
          ImplicitModuleDefinition.new
        ]
      end

      it 'should not overlap' do
        first = subject[0].send(:available)
        second = subject[1].send(:available)

        expect(first).not_to include(second)
      end
    end
  end

  describe 'instantiation' do
    subject do
      ExplicitModuleDefinition.new
    end

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
        expect { subject.send(:create, :does_not_exist) }.to \
          raise_error('Unknown type to instantiate: :does_not_exist. Available types are: [:One, :Three, :Two]')
      end
    end

    context 'snake cased symbol' do
      subject do
        SnakeCaseModuleDefinition.new
      end

      it 'should return instance' do
        expect(subject.send(:create, :snake_case)).to be_an_instance_of(SnakeCase::SnakeCase)
      end

      it 'should prefer explicit type' do
        expect(subject.send(:create, :Snake_Case)).to be_an_instance_of(SnakeCase::Snake_Case)
      end
    end

    context 'instantiation fails' do
      class WillFail
        include Rake::Funnel::Support::InstantiateSymbol

        class Failure
          def initialize
            raise 'BAM!'
          end
        end
      end

      subject do
        WillFail.new
      end

      it 'should fail' do
        expect { subject.send(:create, :Failure) }.to raise_error 'BAM!'
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
          def initialize; end
        end

        class Single
          def initialize(_arg); end
        end

        class Multiple
          def initialize(_arg1, _arg2); end
        end
      end

      class WithArgs
        include Rake::Funnel::Support::InstantiateSymbol
        instantiate CreatableWithArgs
      end

      subject do
        WithArgs.new
      end

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
