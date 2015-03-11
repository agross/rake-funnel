require 'tmpdir'

include Rake
include Rake::Funnel::Support
include Rake::Funnel::Support::SideBySideSpecs

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
  end

  describe 'execution' do
    subject {
      described_class.new do |t|
        t.projects = %w(**/*.??proj)
        t.references = %w(Ref-1)
        t.specs = %w(*Specs.cs **/*Specs.cs)
        t.enabled = enabled
      end
    }

    before {
      allow(Remover).to receive(:remove)
    }

    before {
      Task[subject.name].invoke
    }

    context 'enabled' do
      let(:enabled) { true }

      it 'should use remover' do
        expect(Remover).to have_received(:remove)
            .with({
                projects: subject.projects,
                references: subject.references,
                specs: subject.specs
              })
      end
    end

    context 'disabled' do
      let(:enabled) { false }

      it 'should do nothing' do
        expect(Remover).not_to have_received(:remove)
      end
    end
  end
end
