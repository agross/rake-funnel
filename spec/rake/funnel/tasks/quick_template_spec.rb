require 'tmpdir'

include Rake
include Rake::Funnel::Support

describe Rake::Funnel::Tasks::QuickTemplate do
  before do
    Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :template }
    its(:search_pattern) { should eq(%w(**/*.erb)) }
    its(:context) { should be_an_instance_of(Binding) }
  end

  describe 'execution' do
    let(:templates) { %w(1.template two/2.template) }

    let(:finder) { instance_double(Finder).as_null_object }
    let(:engine) { TemplateEngine }

    before do
      allow(finder).to receive(:all_or_default).and_return(templates)
      allow(Finder).to receive(:new).and_return(finder)
      allow(engine).to receive(:render).and_return('file content')
      allow(Rake).to receive(:rake_output_message)
      allow(File).to receive(:read).and_return('template content')
      allow(File).to receive(:write)
    end

    subject! { described_class.new }

    before do
      Task[subject.name].invoke
    end

    it 'should report created files' do
      templates.each do |template|
        expect(Rake).to have_received(:rake_output_message).with("Creating file #{template.ext}")
      end
    end

    it 'should read all templates' do
      templates.each do |template|
        expect(File).to have_received(:read).with(template)
      end
    end

    it 'should render all templates' do
      templates.each do |template|
        expect(engine).to have_received(:render).with('template content', template, subject.context)
      end
    end

    it 'should write all files' do
      templates.each do |template|
        expect(File).to have_received(:write).with(template.ext, 'file content')
      end
    end
  end
end
