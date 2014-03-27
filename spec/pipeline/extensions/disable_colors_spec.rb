require 'pipeline'
require 'smart_colored'
require 'smart_colored/extend'

describe Pipeline::Extensions::DisableColors do
  context 'when connected to a terminal' do
    before { $stdout.stub(:tty?).and_return(true) }

    it 'should color strings' do
      'foo'.colored.green.should == "\e[32mfoo\e[0m"
    end

    it 'should color strings with extension' do
      'foo'.green.should == "\e[32mfoo\e[0m"
    end

    it 'should support combinators' do
      'foo'.green.inverse.bold.should == "\e[1;7;32mfoo\e[0m"
    end
  end

  context 'when not connected to a terminal' do
    before { $stdout.stub(:tty?).and_return(false) }

    it 'should not color strings' do
      'foo'.colored.green.should == 'foo'
    end

    it 'should not color strings with extension' do
      'foo'.green.should == 'foo'
    end

    it 'should support combinators' do
      'foo'.green.inverse.bold.should == 'foo'
    end
  end
end
