require 'rake/funnel'

include Rake::Funnel::Support

describe Rake::Funnel::Support::Mapper do
  describe 'Manual debugging test case' do
    it 'should work' do
      args = {
        unset: nil,
        simple: 1,
        array: [1, 2, nil],
        hash: { one: 1, two: 2, unset: nil },
        enum_hash: [{ one: 1 }, { two: 2 }, { unset: nil }]
      }

      _ = subject.map(args)
      expect(_).not_to be_empty

      skip('for manual testing only')
    end
  end

  class CustomMapper
    def generate_from(_)
      [
        ['-', 'switch'],
        ['-', :some_switch],
        ['-', :another_switch, '=', :some_value],
        ['-string switch', '=', 'string value']
      ]
    end
  end

  describe 'mapping' do
    it 'should support nil args' do
      expect(subject.map(nil)).to be_empty
    end

    it 'should support empty args' do
      expect(subject.map({})).to be_empty
    end
  end

  describe 'mapper style' do
    context 'default mapper' do
      it 'should use default mapper' do
        expect(described_class.new).to be
      end
    end

    context 'unknown mapper' do
      it 'should fail' do
        expect { described_class.new(:unknown) }.to raise_error(/^Something went wrong while creating the 'unknown' mapper/)
      end
    end

    context 'nil mapper' do
      it 'should fail' do
        expect { described_class.new(nil) }.to raise_error(/You cannot use a 'nil' mapper. Available mappers are: \w+/)
      end
    end

    context 'custom mapper' do
      it 'should take custom mapper instance' do
        expect(described_class.new(CustomMapper.new)).to be
      end
    end
  end

  describe 'mapper output' do
    subject { described_class.new(CustomMapper.new) }

    it 'should join nested arrays' do
      expect(subject.map).to include('-switch')
    end

    describe 'snake case to camel case conversion' do
      it 'should convert symbols keys' do
        expect(subject.map).to include('-someSwitch')
      end

      it 'should convert symbol values' do
        expect(subject.map).to include('-anotherSwitch=someValue')
      end

      it 'should not convert strings' do
        expect(subject.map).to include('-string switch=string value')
      end
    end
  end
end