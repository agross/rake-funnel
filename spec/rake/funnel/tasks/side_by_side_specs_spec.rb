require 'tmpdir'

describe Rake::Funnel::Tasks::SideBySideSpecs do
  before do
    Rake::Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :compile }
    its(:projects) { should == %w(**/*.csproj **/*.vbproj **/*.fsproj) }
    its(:references) { should == [] }
    its(:specs) { should == %w(*Specs.cs *Tests.cs) }
    its(:enabled) { should == false }
    its(:packages) { should == [] }
  end

  describe 'execution' do
    subject do
      described_class.new do |t|
        t.projects = %w(**/*.??proj)
        t.references = %w(Ref)
        t.specs = %w(*Specs.cs **/*Specs.cs)
        t.enabled = enabled
        t.packages = %w(Package)
      end
    end

    before do
      allow(Rake::Funnel::Support::SpecsRemover).to receive(:remove)
    end

    before do
      Rake::Task[subject.name].invoke
    end

    context 'enabled' do
      let(:enabled) { true }

      it 'should use remover' do
        expect(Rake::Funnel::Support::SpecsRemover).to have_received(:remove)
          .with(projects: subject.projects,
                references: subject.references,
                specs: subject.specs,
                packages: subject.packages)
      end
    end

    context 'disabled' do
      let(:enabled) { false }

      it 'should do nothing' do
        expect(Rake::Funnel::Support::SpecsRemover).not_to have_received(:remove)
      end
    end
  end
end
