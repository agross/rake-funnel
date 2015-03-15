describe Rake::Funnel::Support::Mapper::Styles::NUnit do
  subject { Mapper.new(:NUnit) }

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
