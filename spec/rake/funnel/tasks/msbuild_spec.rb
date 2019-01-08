# frozen_string_literal: true

describe Rake::Funnel::Tasks::MSBuild do # rubocop:disable RSpec/FilePath
  before do
    Rake::Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :compile }
    its(:project_or_solution) { should be_instance_of(Rake::Funnel::Support::Finder) }
    its(:args) { should == {} }
    its(:search_pattern) { should == %w(**/*.sln) }
    its(:msbuild) { should be_nil }

    describe 'build tool finder' do
      before do
        allow(Rake::Funnel::Support::MSBuild::BuildTool).to receive(:find).and_return('build tool')
      end

      it 'should use build tool finder' do
        expect(subject.msbuild_finder.call).to eq('build tool')
      end
    end
  end

  describe 'execution' do
    let(:args) { {} }

    let(:mapper) { instance_double(Rake::Funnel::Support::Mapper).as_null_object }
    let(:finder) { instance_double(Rake::Funnel::Support::Finder).as_null_object }

    before do
      allow(subject).to receive(:sh)

      allow(Rake::Funnel::Support::Mapper).to receive(:new).and_return(mapper)
      allow(Rake::Funnel::Support::Finder).to receive(:new).and_return(finder)
      allow(Rake::Funnel::Support::MSBuild::BuildTool).to receive(:find)
    end

    before do
      Rake::Task[subject.name].invoke
    end

    it 'should use solution finder' do
      expect(finder).to have_received(:single)
    end

    it 'should use MSBuild finder' do
      expect(Rake::Funnel::Support::MSBuild::BuildTool).to have_received(:find)
    end

    it 'should use MSBuild mapper' do
      expect(Rake::Funnel::Support::Mapper).to have_received(:new).with(:MSBuild)
    end

    it 'should map arguments' do
      expect(mapper).to have_received(:map).with(args)
    end

    it 'should run with sh' do
      expect(subject).to have_received(:sh)
    end

    describe 'overriding defaults' do
      context 'when msbuild executable is specified' do
        subject do
          described_class.new do |t|
            t.msbuild = 'custom build tool.exe'
          end
        end

        its(:msbuild) { should == 'custom build tool.exe' }
      end

      context 'when project or solution is specified' do
        before do
          allow(Rake::Funnel::Support::Finder).to receive(:new).and_call_original
        end

        subject do
          described_class.new do |t|
            t.project_or_solution = 'project.sln'
          end
        end

        its(:project_or_solution) { should be_instance_of(Rake::Funnel::Support::Finder) }

        it 'should set project or solution' do
          expect(Rake::Funnel::Support::Finder).to have_received(:new)
            .with('project.sln',
                  subject,
                  'No projects or more than one project found.')
        end
      end
    end
  end
end
