describe Rake::Funnel::Extensions::DisableColors do
  context 'when connected to a terminal' do
    before { allow($stdout).to receive(:tty?).and_return(true) }

    it 'should color strings' do
      expect('foo'.colored.green).to eq("\e[32mfoo\e[0m")
    end

    it 'should color strings with extension' do
      expect('foo'.green).to eq("\e[32mfoo\e[0m")
    end

    it 'should support combinators' do
      expect('foo'.green.inverse.bold).to eq("\e[1;7;32mfoo\e[0m")
    end
  end

  context 'when not connected to a terminal' do
    before { allow($stdout).to receive(:tty?).and_return(false) }

    it 'should not color strings' do
      expect('foo'.colored.green).to eq('foo')
    end

    it 'should not color strings with extension' do
      expect('foo'.green).to eq('foo')
    end

    it 'should support combinators' do
      expect('foo'.green.inverse.bold).to eq('foo')
    end
  end
end
