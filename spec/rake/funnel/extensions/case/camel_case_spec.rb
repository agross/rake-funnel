# frozen_string_literal: true

describe Rake::Funnel::Extensions::Case::CamelCase do
  it 'should not touch values without underscores' do
    expect('foo'.camelize).to eq('foo')
  end

  it 'should convert strings with underscores' do
    expect('foo_bar'.camelize).to eq('fooBar')
  end

  it 'should convert symbols to string' do
    expect(:foo.camelize).to eq('foo')
  end

  it 'should convert symbols with underscores' do
    expect(:foo_bar.camelize).to eq('fooBar')
  end
end
