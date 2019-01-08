# frozen_string_literal: true

describe Rake::Funnel::Support::Mapper::Styles::NUnit do # rubocop:disable RSpec/FilePath
  subject { Rake::Funnel::Support::Mapper.new(:NUnit) }

  describe 'prefix' do
    before do
      allow(Rake::Win32).to receive(:windows?).and_return(windows?)
    end

    context 'on Windows' do
      let(:windows?) { true }

      it "should use '/'" do
        expect(subject.map(switch: nil)).to eq(['/switch'])
      end
    end

    context 'not on Windows' do
      let(:windows?) { false }

      it "should use '-'" do
        expect(subject.map(switch: nil)).to eq(['-switch'])
      end
    end
  end
end
