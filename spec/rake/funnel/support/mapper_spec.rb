require 'rake/funnel'

include Rake::Funnel::Support

describe Rake::Funnel::Support::Mapper do
  describe 'Manual debugging NUnit test case' do
    subject { Rake::Funnel::Support::Mapper.new(:NUnit) }

    it 'should work' do
      args = { switch: [{ one: 1 }, { two: 2 }] }
      subject.map args
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

  subject { described_class.new(CustomMapper.new) }

  describe 'mapping' do
    it 'should support nil args' do
      subject.map(nil)
    end
  end

  describe 'custom mapper' do
    it 'should take custom mapper' do
      expect(subject).to be
    end
  end

  describe 'mapper output' do
    it 'should join nested arrays' do
      expect(subject.map).to include('-switch')
    end
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
