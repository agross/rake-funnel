require 'rake/funnel'

include Rake::Funnel::Support

MapperStyles.constants.reject { |x| x == :MSDeploy }.each do |style|
  style_path = MapperStyles.const_get(style)
  describe style_path do
    subject {
      Rake::Funnel::Support::Mapper.new(style)
    }

    let (:style) {
      MapperStyles.const_get(style).new
    }

    def styled(switch, key = nil, value = nil)
      [
        style.prefix,
        switch,
        key && style.separator,
        key && key,
        value && style.value_separator,
        value && value
      ].join
    end

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
        expect(subject.map(args)).to match_array([styled('switch', 'true')])
      end

      it 'should convert switch => <truthy>' do
        args = { switch: 1 }
        expect(subject.map(args)).to match_array([styled('switch', '1')])
      end

      it 'should convert switch => <symbol>' do
        args = { switch: :one }
        expect(subject.map(args)).to match_array([styled('switch', 'one')])
      end

      it 'should convert switch => <string>' do
        args = { switch: 'one' }
        expect(subject.map(args)).to match_array([styled('switch', 'one')])
      end

      it 'should convert switch => <truthy> enumerable' do
        args = { switch: [true, 1] }
        expect(subject.map(args)).to match_array(
            [
              styled('switch', 'true'),
              styled('switch', '1')
            ])
      end

      it 'should convert hash values' do
        args = { switch: { foo: true, bar: true } }
        expect(subject.map(args)).to match_array(
            [
              styled('switch', 'foo', 'true'),
              styled('switch', 'bar', 'true')
            ])
      end

      it 'should convert enumerable hash values' do
        args = { switch: [{ foo: true, bar: 1 }, { baz: :baz, foobar: 'foobar' }] }
        expect(subject.map(args)).to match_array(
            [
              styled('switch', 'foo', 'true'),
              styled('switch', 'bar', '1'),
              styled('switch', 'baz', 'baz'),
              styled('switch', 'foobar', 'foobar'),
            ])
      end
    end

    describe 'falsy arguments' do
      it 'should convert switch => <false>' do
        args = { switch: false }
        expect(subject.map(args)).to match_array([styled('switch', 'false')])
      end

      it 'should convert switch => <falsy>' do
        args = { switch: nil }
        expect(subject.map(args)).to match_array([styled('switch')])
      end

      it 'should convert switch => <falsy> enumerable' do
        args = { switch: [false, nil] }
        expect(subject.map(args)).to match_array(
            [
              styled('switch', 'false'),
              styled('switch')
            ])
      end

      it 'should convert hash values' do
        args = { switch: { foo: false, bar: nil } }
        expect(subject.map(args)).to match_array(
            [
              styled('switch', 'foo', 'false'),
              styled('switch', 'bar')
            ])
      end

      it 'should convert enumerable hash values' do
        args = { switch: [{ foo: false }, { bar: nil }] }
        expect(subject.map(args)).to match_array(
            [
              styled('switch', 'foo', 'false'),
              styled('switch', 'bar')
            ])
      end
    end

    describe 'complex types' do
      it 'should convert switch => <enumerable>' do
        args = { switch: [1, 'two'] }
        expect(subject.map(args)).to match_array(
            [
              styled('switch', '1'),
              styled('switch', 'two')
            ])
      end

      it 'should convert switch => <hash>' do
        args = { switch: { one: 1, two: 2 } }
        expect(subject.map(args)).to match_array(
            [
              styled('switch', 'one', '1'),
              styled('switch', 'two', '2')
            ])
      end

      it 'should convert switch => <enumerable of hash>' do
        args = { switch: [{ one: 1 }, { two: 2 }] }
        expect(subject.map(args)).to match_array(
            [
              styled('switch', 'one', '1'),
              styled('switch', 'two', '2')
            ])
      end
    end

    describe 'snake case to camel case conversion' do
      it 'should convert symbols keys' do
        args = { some_switch: 1 }
        expect(subject.map(args)).to match_array([styled('someSwitch', '1')])
      end

      it 'should convert symbol values' do
        args = { switch: :some_value }
        expect(subject.map(args)).to match_array([styled('switch', 'someValue')])
      end

      it 'should convert enumerable values' do
        args = { switch: [:some_value] }
        expect(subject.map(args)).to match_array([styled('switch', 'someValue')])
      end

      it 'should convert hash values' do
        args = { switch: { key: :some_value } }
        expect(subject.map(args)).to match_array([styled('switch', 'key', 'someValue')])
      end

      it 'should convert hash keys' do
        args = { switch: { some_key: true } }
        expect(subject.map(args)).to match_array([styled('switch', 'someKey', 'true')])
      end

      it 'should convert enumerable hash values' do
        args = { switch: [{ key: :some_value }] }
        expect(subject.map(args)).to match_array([styled('switch', 'key', 'someValue')])
      end

      it 'should convert enumerable hash keys' do
        args = { switch: [{ some_key: true }] }
        expect(subject.map(args)).to match_array([styled('switch', 'someKey', 'true')])
      end

      it 'should not convert strings' do
        args = { 'some_switch' => 'some_value' }
        expect(subject.map(args)).to match_array([styled('some_switch', 'some_value')])
      end
    end
  end
end
