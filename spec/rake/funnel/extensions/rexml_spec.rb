# rubocop:disable RSpec/FilePath

describe Rake::Funnel::Extensions::REXML::Functions do
  let(:xml) do
    <<XML
  <editors xmlns="http://example.com">
    <editor id="emacs">EMACS</editor>
    <editor id="vi">VIM</editor>
    <editor id="notepad">Notepad</editor>
  </editors>
XML
  end

  subject { REXML::Document.new(xml) }

  it 'should support lower-case function' do
    expect(REXML::XPath.match(subject, "//editor[lower-case(text())='vim']").first.to_s).to match(/VIM/)
  end

  it 'should support matches function' do
    expect(REXML::XPath.match(subject, "//editor[matches(@id, '*pad')]").first.to_s).to match(/Notepad/)
  end
end
