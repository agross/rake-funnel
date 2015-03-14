include Rake
include Rake::Funnel
include Rake::Funnel::Support
include Rake::Funnel::Support::MSBuild

describe Rake::Funnel::Tasks::MSBuild do
  before {
    Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :compile }
    its(:project_or_solution) { should be_instance_of(Finder) }
    its(:args) { should == {} }
    its(:search_pattern) { should == %w(**/*.sln) }

    describe 'build tool' do
      before {
        allow(BuildTool).to receive(:find).and_return('build tool')
      }

      it 'should use build tool finder' do
        expect(subject.msbuild).to eq('build tool')
      end
    end
  end

  describe 'execution' do
    let(:args) { {} }

    let(:mapper) { double(Mapper).as_null_object }
    let(:finder) { double(Finder).as_null_object }

    before {
      allow(subject).to receive(:sh)

      allow(Mapper).to receive(:new).and_return(mapper)
      allow(Finder).to receive(:new).and_return(finder)
    }

    before {
      Task[subject.name].invoke
    }

    it 'should use solution finder' do
      expect(finder).to have_received(:single)
    end

    it 'should use MSBuild mapper' do
      expect(Mapper).to have_received(:new).with(:MSBuild)
    end

    it 'should map arguments' do
      expect(mapper).to have_received(:map).with(args)
    end

    it 'should run with sh' do
      expect(subject).to have_received(:sh)
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
          allow(Finder).to receive(:new).and_call_original
        }

        subject {
          described_class.new do |t|
            t.project_or_solution = 'project.sln'
          end
        }

        its(:project_or_solution) { should be_instance_of(Finder) }

        it 'should set project or solution' do
          expect(Finder).to have_received(:new).with('project.sln', subject, 'No projects or more than one project found.')
        end
      end
    end
  end
end
