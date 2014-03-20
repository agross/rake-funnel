include Pipeline::Tasks::MSDeploySupport

describe Mapper do
  describe 'no arguments' do
    it 'should convert no args to []' do
      Mapper.map.should =~ []
    end

    it 'should convert {} to []' do
      Mapper.map({}).should =~ []
    end
  end

  describe 'truthy arguments' do
    it 'should convert verb => <true>' do
      args = { verb: true }
      Mapper.map(args).should =~ ['-verb']
    end

    it 'should convert verb => <truthy arg>' do
      args = { verb: 1 }
      Mapper.map(args).should =~ ['-verb:1']
    end

    it 'should convert verb => <symbol>' do
      args = { verb: :one }
      Mapper.map(args).should =~ ['-verb:one']
    end

    it 'should convert verb => <string>' do
      args = { verb: 'one' }
      Mapper.map(args).should =~ ['-verb:one']
    end

    it 'should convert verb => <true> enumerable' do
      args = { verb: [true] }
      Mapper.map(args).should =~ ['-verb']
    end

    it 'should convert hash values' do
      args = { verb: { key: true } }
      Mapper.map(args).should =~ ['-verb:key=true']
    end

    it 'should convert enumerable hash values' do
      args = { verb: [{ key: true }] }
      Mapper.map(args).should =~ ['-verb:key=true']
    end
  end

  describe 'falsy arguments' do
    it 'should omit verb => <false>' do
      args = { verb: false }
      Mapper.map(args).should =~ []
    end

    it 'should omit verb => <falsy>' do
      args = { verb: nil }
      Mapper.map(args).should =~ []
    end

    it 'should omit verb => <false> enumerable' do
      args = { verb: [false] }
      Mapper.map(args).should =~ []
    end

    it 'should omit verb => <falsy> enumerable' do
      args = { verb: [nil] }
      Mapper.map(args).should =~ []
    end

    it 'should convert <false> hash values' do
      args = { verb: { key: false } }
      Mapper.map(args).should =~ ['-verb:key=false']
    end

    it 'should omit <falsy> hash values' do
      args = { verb: { key: nil } }
      Mapper.map(args).should =~ []
    end

    it 'should convert <false> enumerable hash values' do
      args = { verb: [{ key: false }] }
      Mapper.map(args).should =~ ['-verb:key=false']
    end

    it 'should omit <falsy> enumerable hash values' do
      args = { verb: [{ key: nil }] }
      Mapper.map(args).should =~ []
    end
  end

  describe 'complex types' do
    it 'should convert verb => <enumerable>' do
      args = { verb: [1, 'two'] }
      Mapper.map(args).should =~ ['-verb:1', '-verb:two']
    end

    it 'should convert verb => <hash>' do
      args = { verb: { one: 1, two: 2 } }
      Mapper.map(args).should =~ ['-verb:one=1,two=2']
    end

    it 'should convert verb => <enumerable of hash>' do
      args = { verb: [{ one: 1 }, { two: 2 }] }
      Mapper.map(args).should =~ ['-verb:one=1', '-verb:two=2']
    end
  end

  describe 'snake case to camel case conversion' do
    it 'should convert symbols keys' do
      args = { some_verb: 1 }
      Mapper.map(args).should =~ ['-someVerb:1']
    end

    it 'should convert symbol values' do
      args = { verb: :some_value }
      Mapper.map(args).should =~ ['-verb:someValue']
    end

    it 'should convert enumerable values' do
      args = { verb: [:some_value] }
      Mapper.map(args).should =~ ['-verb:someValue']
    end

    it 'should convert hash values' do
      args = { verb: { key: :some_value } }
      Mapper.map(args).should =~ ['-verb:key=someValue']
    end

    it 'should convert enumerable hash values' do
      args = { verb: [{ key: :some_value }] }
      Mapper.map(args).should =~ ['-verb:key=someValue']
    end

    it 'should not convert strings' do
      args = { some_verb: 'some_value' }
      Mapper.map(args).should =~ ['-someVerb:some_value']
    end
  end

  describe 'whitespace' do
    it 'should enclose keys in "' do
      args = { 'some key' => 1 }
      Mapper.map(args).should =~ ['-"some key":1']
    end

    it 'should enclose hash keys in "' do
      args = { verb: { 'some key' => 1 } }
      Mapper.map(args).should =~ ['-verb:"some key"=1']
    end

    it 'should enclose enumerable hash keys in "' do
      args = { verb: [{ 'some key' => 1 }] }
      Mapper.map(args).should =~ ['-verb:"some key"=1']
    end

    it 'should enclose values in "' do
      args = { verb: 'some value' }
      Mapper.map(args).should =~ ['-verb:"some value"']
    end

    it 'should enclose enumerable values in "' do
      args = { verb: ['some value'] }
      Mapper.map(args).should =~ ['-verb:"some value"']
    end

    it 'should enclose hash values in "' do
      args = { verb: { key: 'some value' } }
      Mapper.map(args).should =~ ['-verb:key="some value"']
    end

    it 'should enclose enumerable hash values in "' do
      args = { verb: [{ key: 'some value' }] }
      Mapper.map(args).should =~ ['-verb:key="some value"']
    end
  end
end
