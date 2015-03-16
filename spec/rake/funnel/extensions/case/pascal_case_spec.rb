describe Rake::Funnel::Extensions::Case::PascalCase do
  it 'should convert strings' do
    expect('foo'.pascalize).to eq('Foo')
  end

  it 'should convert strings with underscores' do
    expect('foo_bar'.pascalize).to eq('FooBar')
  end

  it 'should convert symbols to string' do
    expect(:foo.pascalize).to eq('Foo')
  end

  it 'should convert symbols with underscores' do
    expect(:foo_bar.pascalize).to eq('FooBar')
  end
end
