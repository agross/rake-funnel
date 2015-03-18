describe Rake::Funnel::Support::SpecsRemover do
  describe 'removal' do
    let(:projects) {}
    let(:references) {}
    let(:specs) {}
    let(:packages) {}

    before {
      allow(File).to receive(:open)
      allow(File).to receive(:write)
      allow(RakeFileUtils).to receive(:rm)
    }

    describe 'arguments' do
      before {
        described_class.remove(projects: projects,
                               references: references,
                               specs: specs,
                               packages: packages)
      }

      context 'string projects' do
        let(:projects) { '**/*.??proj' }

        it 'should succeed' do
          expect(true).to be(true)
        end
      end

      context 'string references' do
        let(:projects) { '**/*.??proj' }
        let(:references) { 'Reference' }

        it 'should succeed' do
          expect(true).to be(true)
        end
      end

      context 'string specs' do
        let(:projects) { '**/*.??proj' }
        let(:specs) { '*Specs.cs' }

        it 'should succeed' do
          expect(true).to be(true)
        end
      end

      context 'string packages' do
        let(:packages) { 'SomePackage' }

        it 'should succeed' do
          expect(true).to be(true)
        end
      end
    end

    describe 'unchanged files' do
      describe Rake::Funnel::Support::SpecsRemover::ProjectFiles do
        let(:projects) { '**/*.??proj' }

        before {
          allow(Dir).to receive(:[]).and_return([:some])
          allow(File).to receive(:read).and_return('<root></root>')
        }

        before {
          described_class.remove_specs_and_references(projects, [], [])
        }

        it 'should not write the project file' do
          expect(File).not_to have_received(:open)
        end
      end

      describe Rake::Funnel::Support::SpecsRemover::PaketReferences do
        let(:projects) { %w(project.proj) }

        before {
          allow(Dir).to receive(:[]).and_return([:some])
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:read).and_return('SomePackage')
        }

        before {
          described_class.remove_packages(projects, [])
        }

        it 'should not write the project file' do
          expect(File).not_to have_received(:write)
        end
      end
    end
  end

  describe 'examples' do
    def content(file, dir = temp_dir)
      File.read(File.join(dir, file))
    end

    def example_dir(example)
      File.join(File.dirname(__FILE__), 'specs_remover', example)
    end

    let(:projects) { %w(**/*.??proj) }
    let(:references) { %w(Some-Ref Ref-Without-HintPath Paket-Ref) }
    let(:specs) { %w(*Specs.cs) }
    let(:packages) { %w(Explicitly-Removed-Package) }

    let(:current_dir) { Dir.pwd }
    let(:temp_dir) { Dir.mktmpdir }

    before {
      allow($stderr).to receive(:puts)
    }

    before {
      FileUtils.cp_r(File.join(example_dir(example), '.'), temp_dir)
      Dir.chdir(temp_dir)
    }

    after {
      Dir.chdir(current_dir)
      FileUtils.rm_rf(temp_dir)
    }

    context 'project' do
      let(:example) { 'project' }

      before {
        described_class.remove(projects: projects,
                               references: references,
                               specs: specs,
                               packages: packages)
      }

      describe 'code files' do
        describe 'production code' do
          it 'should be kept' do
            expect(File).to exist('FooCode.cs')
          end
        end

        describe 'uncompiled code' do
          it 'should be kept' do
            expect(File).to exist('uncompiled-code/BarCode.cs')
            expect(File).to exist('uncompiled-code/BarSpecs.cs')
          end
        end

        describe 'specs' do
          it 'should be deleted' do
            expect(File).not_to exist('Specs.cs')
            expect(File).not_to exist('FooSpecs.cs')
          end
        end
      end

      describe 'projects' do
        it 'should remove references' do
          expect(content('Sample.csproj')).not_to include(*references)
        end

        it 'should remove compiled specs' do
          expect(content('Sample.csproj')).not_to include(*%w(Specs.cs SampleSpecs.cs DoesNotExistSpecs.cs))
        end
      end

      describe 'paket references' do
        describe 'paket.references for projects' do
          it 'should remove packages' do
            expect(content('paket.references')).not_to include(*(packages + references))
          end

          it 'should keep other packages' do
            expect(content('paket.references')).to include('Untouched')
          end
        end

        describe 'unused paket.references' do
          it 'should not be modified' do
            file = 'uncompiled-code/paket.references'
            original_content = content(file, example_dir(example))

            expect(content(file)).to eq(original_content)
          end
        end
      end
    end

    context 'project-specific paket.references' do
      let(:example) { 'project-specific paket.references' }

      before {
        described_class.remove(projects: projects,
                               references: references,
                               specs: specs,
                               packages: packages)
      }

      describe 'paket.references for project' do
        it 'should remove packages' do
          expect(content('Sample.csproj.paket.references')).not_to include(*(packages + references))
        end

        it 'should keep other packages' do
          expect(content('Sample.csproj.paket.references')).to include('Untouched')
        end
      end

      describe 'global paket.references' do
        it 'should not be modified' do
          file = 'paket.references'
          original_content = content(file, example_dir(example))

          expect(content(file)).to eq(original_content)
        end
      end
    end
  end
end
