require 'rake/funnel'

include Rake::Funnel
include Rake::Funnel::Tasks

describe MSBuild do
  before {
    Rake::Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :compile }
    its(:project_or_solution) { should be_instance_of(Support::Finder) }
    its(:args) { should == {} }
    its(:search_pattern) { should == %w(**/*.sln) }

    describe 'build tool' do
      before {
        allow(MSBuildSupport::BuildTool).to receive(:find).and_return('build tool')
      }

      it 'should use build tool finder' do
        expect(subject.msbuild).to eq('build tool')
      end
    end
  end

  describe 'overriding defaults' do
    context 'when msbuild executable is specified' do
      subject {
        described_class.new do |t|
          t.msbuild = 'custom build tool.exe'
        end
      }

      its(:msbuild) { should == 'custom build tool.exe' }
    end

    context 'when project or solution is specified' do
      before {
        allow(Support::Finder).to receive(:new).and_call_original
      }

      subject {
        described_class.new do |t|
          t.project_or_solution = 'project.sln'
        end
      }

      its(:project_or_solution) { should be_instance_of(Support::Finder) }

      it 'should set project or solution' do
        expect(Support::Finder).to have_received(:new).with('project.sln', subject, 'No projects or more than one project found.')
      end
    end
  end

  describe 'execution' do
    let(:args) { {} }

    let(:mapper) { double(Support::Mapper).as_null_object }
    let(:finder) { double(Support::Finder).as_null_object }

    before {
      allow(subject).to receive(:sh)

      allow(Support::Mapper).to receive(:new).and_return(mapper)
      allow(Support::Finder).to receive(:new).and_return(finder)
    }

    before {
      Rake::Task[subject.name].invoke
    }

    it 'should use solution finder' do
      expect(finder).to have_received(:single)
    end

    it 'should use MSBuild mapper' do
      expect(Support::Mapper).to have_received(:new).with(:MSBuild)
    end

    it 'should map arguments' do
      expect(mapper).to have_received(:map).with(args)
    end

    it 'should run with sh' do
      expect(subject).to have_received(:sh)
    end
  end
end
