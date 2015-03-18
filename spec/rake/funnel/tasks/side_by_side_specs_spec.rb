require 'tmpdir'

include Rake
include Rake::Funnel::Support

describe Rake::Funnel::Tasks::SideBySideSpecs do
  before {
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :compile }
    its(:projects) { should == %w(**/*.csproj **/*.vbproj **/*.fsproj) }
    its(:references) { should == [] }
    its(:specs) { should == %w(*Specs.cs **/*Specs.cs *Tests.cs **/*Tests.cs) }
    its(:enabled) { should == false }
    its(:paket_references) { should == %w(**/*paket.references) }
    its(:packages) { should == [] }
  end

  describe 'execution' do
    subject {
      described_class.new do |t|
        t.projects = %w(**/*.??proj)
        t.references = %w(Ref)
        t.specs = %w(*Specs.cs **/*Specs.cs)
        t.enabled = enabled
        t.paket_references = %w(paket.references)
        t.packages = %w(Package)
      end
    }

    before {
      allow(SpecsRemover).to receive(:remove)
    }

    before {
      Task[subject.name].invoke
    }

    context 'enabled' do
      let(:enabled) { true }

      it 'should use remover' do
        expect(SpecsRemover).to have_received(:remove)
            .with(projects: subject.projects,
                  references: subject.references,
                  specs: subject.specs,
                  paket_references: subject.paket_references,
                  packages: subject.packages)
      end
    end

    context 'disabled' do
      let(:enabled) { false }

      it 'should do nothing' do
        expect(SpecsRemover).not_to have_received(:remove)
      end
    end
  end
end
