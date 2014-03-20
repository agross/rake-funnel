require 'pipeline'

describe Pipeline::Patches::CamelCase do
  it 'should not touch values without underscores' do
    'foo'.camelize.should == 'foo'
  end

  it 'should convert strings with underscores' do
    'foo_bar'.camelize.should == 'fooBar'
  end

  it 'should convert symbols to string' do
    :foo.camelize.should == 'foo'
  end

  it 'should convert symbols with underscores' do
    :foo_bar.camelize.should == 'fooBar'
  end
end
