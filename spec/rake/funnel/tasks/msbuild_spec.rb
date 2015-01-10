require 'rake/funnel'

include Rake::Funnel
include Rake::Funnel::Tasks

describe MSBuild do
  before {
    Rake::Task.clear
  }

  describe 'defaults' do
    its(:name) { should == :compile }
    its(:project_or_solution) { should == nil }
    its(:args) { should == {} }
    its(:search_pattern) { should == %w(**/*.sln) }

    describe 'build tool' do
      before {
        allow(Rake::Win32).to receive(:windows?).and_return(windows?)
      }

      context 'on Windows', platform: :win32 do
        let(:windows?) { true }

        its(:msbuild) { should =~ /msbuild\.exe$/ }
      end

      context 'not on Windows' do
        let(:windows?) { false }

        its(:msbuild) { should == 'xbuild' }
      end
    end
  end

  describe 'overriding defaults' do
    context 'when msbuild executable is specified' do
      subject {
        described_class.new do |t|
          t.msbuild = 'msbuild.exe'
        end
      }

      its(:msbuild) { should == 'msbuild.exe' }
    end

    context 'when project or solution is specified' do
      subject {
        described_class.new do |t|
          t.project_or_solution = 'project.sln'
        end
      }

      its(:project_or_solution) { should == 'project.sln' }
    end
  end

  describe 'execution' do
    before {
      allow(subject).to receive(:sh)
    }

    describe 'solution finder' do
      let(:generate) { [] }

      let!(:dir) {
        tmp = Dir.mktmpdir

        ([] << generate).flatten.each do |g|
          file = "#{tmp}/#{g}"

          FileUtils.mkdir_p(File.dirname(file))
          FileUtils.touch(file)
        end

        tmp
      }

      after { FileUtils.rm_rf dir }

      subject! {
        described_class.new do |t|
          t.search_pattern = %W(#{dir}/**/*.sln #{dir}/**/*.??proj)
          t.args = nil
        end
      }

      context 'no solution and project' do
        it 'should fail' do
          expect(lambda { Rake::Task[subject.name].invoke }).to raise_error(AmbiguousFileError)
        end
      end

      context 'more than one solution' do
        let(:generate) { %w(foo/project1.sln foo/project2.sln) }

        it 'should fail' do
          expect(lambda { Rake::Task[subject.name].invoke }).to raise_error(AmbiguousFileError)
        end
      end

      context 'more than one project' do
        let(:generate) { %w(foo/project.csproj foo/project.fsproj) }

        it 'should fail' do
          expect(lambda { Rake::Task[subject.name].invoke }).to raise_error(AmbiguousFileError)
        end
      end

      context 'one solution' do
        let(:generate) { 'foo/project.sln' }

        it 'should build solution' do
          Rake::Task[subject.name].invoke

          expect(subject).to have_received(:sh).with([subject.msbuild, subject.project_or_solution])
        end
      end

      context 'one project' do
        let(:generate) { 'foo/project.fsproj' }

        it 'should build project' do
          Rake::Task[subject.name].invoke

          expect(subject).to have_received(:sh).with([subject.msbuild, subject.project_or_solution])
        end
      end
    end

    describe 'arguments' do
      let(:args) {}

      subject! {
        described_class.new do |t|
          t.args = args
          t.project_or_solution = 'dummy value such that it runs'
        end
      }

      describe 'key-value' do
        context 'value given' do
          let(:args) { { target: 'Rebuild' } }

          it 'should pass arg' do
            Rake::Task[subject.name].invoke

            expect(subject).to have_received(:sh).with([subject.msbuild, subject.project_or_solution, '/target:Rebuild'])
          end
        end

        context 'value nil' do
          let(:args) { { target: nil } }

          it 'should not pass arg' do
            Rake::Task[subject.name].invoke

            expect(subject).to have_received(:sh).with([subject.msbuild, subject.project_or_solution, '/target'])
          end
        end
      end

      describe 'flags' do
        context 'flag on' do
          let(:args) { { node_reuse: true } }

          it 'should pass arg' do
            Rake::Task[subject.name].invoke

            expect(subject).to have_received(:sh).with([subject.msbuild, subject.project_or_solution, '/nodeReuse:true'])
          end
        end

        context 'flag off' do
          let(:args) { { node_reuse: false } }

          it 'should not pass arg' do
            Rake::Task[subject.name].invoke

            expect(subject).to have_received(:sh).with([subject.msbuild, subject.project_or_solution, '/nodeReuse:false'])
          end
        end

        context 'flag nil' do
          let(:args) { { nologo: nil } }

          it 'should not pass arg' do
            Rake::Task[subject.name].invoke

            expect(subject).to have_received(:sh).with([subject.msbuild, subject.project_or_solution, '/nologo'])
          end
        end
      end

      describe 'properties' do
        context 'value given' do
          let(:args) { { property: { Configuration: 'Debug' } } }

          it 'should pass arg' do
            Rake::Task[subject.name].invoke

            expect(subject).to have_received(:sh).with([subject.msbuild, subject.project_or_solution, '/property:Configuration=Debug'])
          end
        end

        context 'value nil' do
          let(:args) { { property: { Configuration: nil } } }

          it 'should not pass arg' do
            Rake::Task[subject.name].invoke

            expect(subject).to have_received(:sh).with([subject.msbuild, subject.project_or_solution, '/property:Configuration'])
          end
        end
      end
    end
  end
end
