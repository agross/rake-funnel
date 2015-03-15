describe Rake::Funnel::Extensions::WindowsPath do
  it 'should convert forward slash to backslash' do
    expect('C:\Foo/bar/baz'.to_windows_path).to eq('C:\Foo\bar\baz')
  end
end
