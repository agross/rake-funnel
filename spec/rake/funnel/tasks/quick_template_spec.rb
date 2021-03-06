# frozen_string_literal: true

require 'tmpdir'

describe Rake::Funnel::Tasks::QuickTemplate do
  before do
    Rake::Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :template }
    its(:search_pattern) { should eq(%w(**/*.erb)) }
    its(:context) { should be_an_instance_of(Binding) }
  end

  describe 'execution' do
    let(:templates) { %w(1.template two/2.template) }

    let(:finder) { instance_double(Rake::Funnel::Support::Finder).as_null_object }
    let(:engine) { Rake::Funnel::Support::TemplateEngine }

    before do
      allow(finder).to receive(:all_or_default).and_return(templates)
      allow(Rake::Funnel::Support::Finder).to receive(:new).and_return(finder)
      allow(engine).to receive(:render).and_return('file content')
      allow($stderr).to receive(:print)
      allow(File).to receive(:read).and_return('template content')
      allow(File).to receive(:write)
    end

    subject! { described_class.new }

    before do
      Rake::Task[subject.name].invoke
    end

    it 'should report created files' do
      templates.each do |template|
        expect($stderr).to have_received(:print).with("Creating file #{template.ext}\n")
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
