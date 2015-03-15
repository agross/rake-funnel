include Rake::Funnel::Support

describe Rake::Funnel::Support::Mapper::Styles::MSDeploy do
  subject { Mapper.new(:MSDeploy) }

  describe 'no arguments' do
    it 'should convert no args to []' do
      expect(subject.map).to match_array([])
    end

    it 'should convert {} to []' do
      expect(subject.map({})).to match_array([])
    end
  end

  describe 'truthy arguments' do
    it 'should convert switch => <true>' do
      args = { switch: true }
      expect(subject.map(args)).to match_array(['-switch:true'])
    end

    it 'should convert switch => <truthy>' do
      args = { switch: 1 }
      expect(subject.map(args)).to match_array(['-switch:1'])
    end

    it 'should convert switch => <symbol>' do
      args = { switch: :one }
      expect(subject.map(args)).to match_array(['-switch:one'])
    end

    it 'should convert switch => <string>' do
      args = { switch: 'one' }
      expect(subject.map(args)).to match_array(['-switch:one'])
    end

    it 'should convert switch => <truthy> enumerable' do
      args = { switch: [true, 1] }
      expect(subject.map(args)).to match_array(%w(-switch:true -switch:1))
    end

    it 'should convert hash values' do
      args = { switch: { foo: true, bar: true } }
      expect(subject.map(args)).to match_array(['-switch:foo=true,bar=true'])
    end

    it 'should convert enumerable hash values' do
      args = { switch: [{ foo: true, bar: 1 }, { baz: :baz, foobar: 'foobar' }] }
      expect(subject.map(args)).to match_array(%w(-switch:foo=true,bar=1 -switch:baz=baz,foobar=foobar))
    end
  end

  describe 'falsy arguments' do
    it 'should convert switch => <false>' do
      args = { switch: false }
      expect(subject.map(args)).to match_array(['-switch:false'])
    end

    it 'should convert switch => <falsy>' do
      args = { switch: nil }
      expect(subject.map(args)).to match_array(['-switch'])
    end

    it 'should convert switch => <falsy> enumerable' do
      args = { switch: [false, nil] }
      expect(subject.map(args)).to match_array(%w(-switch:false -switch))
    end

    it 'should convert hash values' do
      args = { switch: { foo: false, bar: nil } }
      expect(subject.map(args)).to match_array(['-switch:foo=false,bar'])
    end

    it 'should convert enumerable hash values' do
      args = { switch: [{ foo: false }, { bar: nil }] }
      expect(subject.map(args)).to match_array(%w(-switch:foo=false -switch:bar))
    end
  end

  describe 'complex types' do
    it 'should convert switch => <enumerable>' do
      args = { switch: [1, 'two'] }
      expect(subject.map(args)).to match_array(%w(-switch:1 -switch:two))
    end

    it 'should convert switch => <hash>' do
      args = { switch: { one: 1, two: 2 } }
      expect(subject.map(args)).to match_array(['-switch:one=1,two=2'])
    end

    it 'should convert switch => <enumerable of hash>' do
      args = { switch: [{ one: 1 }, { two: 2 }] }
      expect(subject.map(args)).to match_array(%w(-switch:one=1 -switch:two=2))
    end
  end

  describe 'snake case to camel case conversion' do
    it 'should convert symbols keys' do
      args = { some_switch: 1 }
      expect(subject.map(args)).to match_array(['-someSwitch:1'])
    end

    it 'should convert symbol values' do
      args = { switch: :some_value }
      expect(subject.map(args)).to match_array(['-switch:someValue'])
    end

    it 'should convert enumerable values' do
      args = { switch: [:some_value] }
      expect(subject.map(args)).to match_array(['-switch:someValue'])
    end

    it 'should convert hash values' do
      args = { switch: { key: :some_value } }
      expect(subject.map(args)).to match_array(['-switch:key=someValue'])
    end

    it 'should convert hash keys' do
      args = { switch: { some_key: true } }
      expect(subject.map(args)).to match_array(['-switch:someKey=true'])
    end

    it 'should convert enumerable hash values' do
      args = { switch: [{ key: :some_value }] }
      expect(subject.map(args)).to match_array(['-switch:key=someValue'])
    end

    it 'should convert enumerable hash keys' do
      args = { switch: [{ some_key: true }] }
      expect(subject.map(args)).to match_array(['-switch:someKey=true'])
    end

    it 'should not convert strings' do
      args = { 'some_switch' => 'some_value' }
      expect(subject.map(args)).to match_array(['-some_switch:some_value'])
    end
  end

  describe 'whitespace' do
    describe 'keys' do
      context 'without quotes' do
        it 'should enclose keys in "' do
          args = { 'some key' => 1 }
          expect(subject.map(args)).to match_array(['-"some key":1'])
        end

        it 'should enclose hash keys in "' do
          args = { switch: { 'some key' => 1 } }
          expect(subject.map(args)).to match_array(['-switch:"some key"=1'])
        end

        it 'should enclose enumerable hash keys in "' do
          args = { switch: [{ 'some key' => 1 }] }
          expect(subject.map(args)).to match_array(['-switch:"some key"=1'])
        end
      end

      context 'with quotes' do
        it 'should escape quotes' do
          args = { 'some "key"' => 1 }
          expect(subject.map(args)).to match_array(['-"some ""key""":1'])
        end

        it 'should escape quotes in hash keys' do
          args = { switch: { 'some "key"' => 1 } }
          expect(subject.map(args)).to match_array(['-switch:"some ""key"""=1'])
        end

        it 'should escape quotes in enumerable hash keys' do
          args = { switch: [{ 'some "key"' => 1 }] }
          expect(subject.map(args)).to match_array(['-switch:"some ""key"""=1'])
        end
      end
    end

    describe 'values' do
      context 'without quotes' do
        it 'should enclose values in "' do
          args = { switch: 'some value' }
          expect(subject.map(args)).to match_array(['-switch:"some value"'])
        end

        it 'should enclose enumerable values in "' do
          args = { switch: ['some value'] }
          expect(subject.map(args)).to match_array(['-switch:"some value"'])
        end

        it 'should enclose hash values in "' do
          args = { switch: { key: 'some value' } }
          expect(subject.map(args)).to match_array(['-switch:key="some value"'])
        end

        it 'should enclose enumerable hash values in "' do
          args = { switch: [{ key: 'some value' }] }
          expect(subject.map(args)).to match_array(['-switch:key="some value"'])
        end
      end

      context 'with quotes' do
        it 'should escape quotes' do
          args = { switch: 'some "value"' }
          expect(subject.map(args)).to match_array(['-switch:"some ""value"""'])
        end

        it 'should escape quotes in enumerable values' do
          args = { switch: ['some "value"'] }
          expect(subject.map(args)).to match_array(['-switch:"some ""value"""'])
        end

        it 'should escape quotes in hash values' do
          args = { switch: { key: 'some "value"' } }
          expect(subject.map(args)).to match_array(['-switch:key="some ""value"""'])
        end

        it 'should escape quotes in enumerable hash values' do
          args = { switch: [{ key: 'some "value"' }] }
          expect(subject.map(args)).to match_array(['-switch:key="some ""value"""'])
        end
      end
    end
  end
end
