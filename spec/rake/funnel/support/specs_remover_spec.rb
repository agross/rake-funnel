describe Rake::Funnel::Support::SpecsRemover do
  describe 'removal' do
    let(:projects) {}
    let(:references) {}
    let(:specs) {}
    let(:paket_references) {}
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
                               paket_references: paket_references,
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
    end

    describe 'unchanged files' do
      let(:project_file) {}
      let(:paket_references_file) {}

      before {
        allow(Dir).to receive(:[]).and_return([])
      }

      before {
        allow(Dir).to receive(:[]).with(projects).and_return([project_file])
        allow(File).to receive(:read).with(project_file).and_return('<root></root>')
      }

      before {
        allow(Dir).to receive(:[]).with(paket_references).and_return([paket_references_file])
        allow(File).to receive(:read).with(paket_references_file).and_return('SomePackage')
      }

      before {
        described_class.remove(projects: projects,
                               references: references,
                               specs: specs,
                               paket_references: paket_references,
                               packages: packages)
      }

      context 'project unchanged' do
        let(:projects) { '**/*.??proj' }
        let(:project_file) { 'project.proj' }

        it 'should not write the project file' do
          expect(File).not_to have_received(:open)
        end
      end

      context 'paket references unchanged' do
        let(:paket_references) { '*paket.references' }
        let(:paket_references_file) { 'paket.references' }

        it 'should not write the references file' do
          expect(File).not_to have_received(:write)
        end
      end
    end
  end

  describe 'example' do
    let(:projects) { %w(**/*.??proj) }
    let(:references) { %w(Sample-Ref-1 Sample-Ref-2 Sample-Ref-3) }
    let(:specs) { %w(*Specs.cs **/*Specs.cs) }
    let(:paket_references) { %w(**/*paket.references) }
    let(:packages) { references }

    let(:temp_dir) { Dir.mktmpdir }

    before {
      FileUtils.cp_r(File.join(File.dirname(__FILE__), 'specs_remover/.'), temp_dir)
    }

    before {
      allow(RakeFileUtils).to receive(:rm)
    }

    before {
      Dir.chdir(temp_dir) do
        described_class.remove(projects: projects,
                               references: references,
                               specs: specs,
                               paket_references: paket_references,
                               packages: packages)
      end
    }

    after {
      FileUtils.rm_rf(temp_dir)
    }

    describe 'code files' do
      it 'should keep production code' do
        expect(RakeFileUtils).not_to have_received(:rm).with('Code.cs')
      end

      it 'should delete specs' do
        expect(RakeFileUtils).to have_received(:rm).with('Specs.cs')
        expect(RakeFileUtils).to have_received(:rm).with('FooSpecs.cs')
        expect(RakeFileUtils).to have_received(:rm).with('subdir/BarSpecs.cs')
      end
    end

    describe 'projects' do
      def project_xml
        File.read(File.join(temp_dir, 'Sample.csproj'))
      end

      it 'should remove references' do
        expect(project_xml).not_to include(*references)
      end

      it 'should remove spec files' do
        expect(project_xml).not_to include('Specs.cs', 'SampleSpecs.cs')
      end
    end

    describe 'paket references' do
      def content(file)
        File.read(File.join(temp_dir, file))
      end

      it 'should remove packages' do
        [
          content('paket.references'),
          content('subdir/foo.paket.references')
        ].each do |content|
          expect(content).not_to include(*packages)
        end
      end

      it 'should keep other packages' do
        [
          content('paket.references'),
          content('subdir/foo.paket.references')
        ].each do |content|
          expect(content).to include('Untouched')
        end
      end
    end
  end
end
