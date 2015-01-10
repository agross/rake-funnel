require 'rake/funnel'

include Rake::Funnel::Support

describe Rake::Funnel::Support::MapperStyles::NUnit do
  subject { Rake::Funnel::Support::Mapper.new(:NUnit) }

  describe 'prefix' do
    before {
      allow(Rake::Win32).to receive(:windows?).and_return(windows?)
    }

    context 'on Windows' do
      let(:windows?) { true }

      it "should use '/'" do
        expect(subject.map({ switch: nil })).to eq(['/switch'])
      end
    end

    context 'not on Windows' do
      let(:windows?) { false }

      it "should use '-'" do
        expect(subject.map({ switch: nil })).to eq(['-switch'])
      end
    end
  end
end
