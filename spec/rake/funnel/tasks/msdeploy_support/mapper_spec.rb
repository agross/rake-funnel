include Rake::Funnel::Tasks::MSDeploySupport

describe Mapper do
  describe 'no arguments' do
    it 'should convert no args to []' do
      expect(Mapper.map).to match_array([])
    end

    it 'should convert {} to []' do
      expect(Mapper.map({})).to match_array([])
    end
  end

  describe 'truthy arguments' do
    it 'should convert verb => <true>' do
      args = { verb: true }
      expect(Mapper.map(args)).to match_array(['-verb'])
    end

    it 'should convert verb => <truthy arg>' do
      args = { verb: 1 }
      expect(Mapper.map(args)).to match_array(['-verb:1'])
    end

    it 'should convert verb => <symbol>' do
      args = { verb: :one }
      expect(Mapper.map(args)).to match_array(['-verb:one'])
    end

    it 'should convert verb => <string>' do
      args = { verb: 'one' }
      expect(Mapper.map(args)).to match_array(['-verb:one'])
    end

    it 'should convert verb => <true> enumerable' do
      args = { verb: [true] }
      expect(Mapper.map(args)).to match_array(['-verb'])
    end

    it 'should convert hash values' do
      args = { verb: { key: true } }
      expect(Mapper.map(args)).to match_array(['-verb:key=true'])
    end

    it 'should convert enumerable hash values' do
      args = { verb: [{ key: true }] }
      expect(Mapper.map(args)).to match_array(['-verb:key=true'])
    end
  end

  describe 'falsy arguments' do
    it 'should omit verb => <false>' do
      args = { verb: false }
      expect(Mapper.map(args)).to match_array([])
    end

    it 'should omit verb => <falsy>' do
      args = { verb: nil }
      expect(Mapper.map(args)).to match_array([])
    end

    it 'should omit verb => <false> enumerable' do
      args = { verb: [false] }
      expect(Mapper.map(args)).to match_array([])
    end

    it 'should omit verb => <falsy> enumerable' do
      args = { verb: [nil] }
      expect(Mapper.map(args)).to match_array([])
    end

    it 'should convert <false> hash values' do
      args = { verb: { key: false } }
      expect(Mapper.map(args)).to match_array(['-verb:key=false'])
    end

    it 'should omit <falsy> hash values' do
      args = { verb: { key: nil } }
      expect(Mapper.map(args)).to match_array([])
    end

    it 'should convert <false> enumerable hash values' do
      args = { verb: [{ key: false }] }
      expect(Mapper.map(args)).to match_array(['-verb:key=false'])
    end

    it 'should omit <falsy> enumerable hash values' do
      args = { verb: [{ key: nil }] }
      expect(Mapper.map(args)).to match_array([])
    end
  end

  describe 'complex types' do
    it 'should convert verb => <enumerable>' do
      args = { verb: [1, 'two'] }
      expect(Mapper.map(args)).to match_array(['-verb:1', '-verb:two'])
    end

    it 'should convert verb => <hash>' do
      args = { verb: { one: 1, two: 2 } }
      expect(Mapper.map(args)).to match_array(['-verb:one=1,two=2'])
    end

    it 'should convert verb => <enumerable of hash>' do
      args = { verb: [{ one: 1 }, { two: 2 }] }
      expect(Mapper.map(args)).to match_array(['-verb:one=1', '-verb:two=2'])
    end
  end

  describe 'snake case to camel case conversion' do
    it 'should convert symbols keys' do
      args = { some_verb: 1 }
      expect(Mapper.map(args)).to match_array(['-someVerb:1'])
    end

    it 'should convert symbol values' do
      args = { verb: :some_value }
      expect(Mapper.map(args)).to match_array(['-verb:someValue'])
    end

    it 'should convert enumerable values' do
      args = { verb: [:some_value] }
      expect(Mapper.map(args)).to match_array(['-verb:someValue'])
    end

    it 'should convert hash values' do
      args = { verb: { key: :some_value } }
      expect(Mapper.map(args)).to match_array(['-verb:key=someValue'])
    end

    it 'should convert enumerable hash values' do
      args = { verb: [{ key: :some_value }] }
      expect(Mapper.map(args)).to match_array(['-verb:key=someValue'])
    end

    it 'should not convert strings' do
      args = { some_verb: 'some_value' }
      expect(Mapper.map(args)).to match_array(['-someVerb:some_value'])
    end
  end

  describe 'whitespace' do
    describe 'keys' do
      context 'without quotes' do
        it 'should enclose keys in "' do
          args = { 'some key' => 1 }
          expect(Mapper.map(args)).to match_array(['-"some key":1'])
        end

        it 'should enclose hash keys in "' do
          args = { verb: { 'some key' => 1 } }
          expect(Mapper.map(args)).to match_array(['-verb:"some key"=1'])
        end

        it 'should enclose enumerable hash keys in "' do
          args = { verb: [{ 'some key' => 1 }] }
          expect(Mapper.map(args)).to match_array(['-verb:"some key"=1'])
        end
        end

      context 'with quotes' do
        it 'should escape quotes' do
          args = { 'some "key"' => 1 }
          expect(Mapper.map(args)).to match_array(['-"some ""key""":1'])
        end

        it 'should escape quotes in hash keys' do
          args = { verb: { 'some "key"' => 1 } }
          expect(Mapper.map(args)).to match_array(['-verb:"some ""key"""=1'])
        end

        it 'should escape quotes in enumerable hash keys' do
          args = { verb: [{ 'some "key"' => 1 }] }
          expect(Mapper.map(args)).to match_array(['-verb:"some ""key"""=1'])
        end
      end
    end

    describe 'values' do
      context 'without quotes' do
        it 'should enclose values in "' do
          args = { verb: 'some value' }
          expect(Mapper.map(args)).to match_array(['-verb:"some value"'])
        end

        it 'should enclose enumerable values in "' do
          args = { verb: ['some value'] }
          expect(Mapper.map(args)).to match_array(['-verb:"some value"'])
        end

        it 'should enclose hash values in "' do
          args = { verb: { key: 'some value' } }
          expect(Mapper.map(args)).to match_array(['-verb:key="some value"'])
        end

        it 'should enclose enumerable hash values in "' do
          args = { verb: [{ key: 'some value' }] }
          expect(Mapper.map(args)).to match_array(['-verb:key="some value"'])
        end
      end

      context 'with quotes' do
        it 'should escape quotes' do
          args = { verb: 'some "value"' }
          expect(Mapper.map(args)).to match_array(['-verb:"some ""value"""'])
        end

        it 'should escape quotes in enumerable values' do
          args = { verb: ['some "value"'] }
          expect(Mapper.map(args)).to match_array(['-verb:"some ""value"""'])
        end

        it 'should escape quotes in hash values' do
          args = { verb: { key: 'some "value"' } }
          expect(Mapper.map(args)).to match_array(['-verb:key="some ""value"""'])
        end

        it 'should escape quotes in enumerable hash values' do
          args = { verb: [{ key: 'some "value"' }] }
          expect(Mapper.map(args)).to match_array(['-verb:key="some ""value"""'])
        end
      end
    end
  end
end
