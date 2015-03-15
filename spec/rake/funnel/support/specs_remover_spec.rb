describe Rake::Funnel::Support::SpecsRemover do
  describe 'removal' do
    let(:projects) { [] }
    let(:references) { [] }
    let(:specs) { [] }

    before {
      allow(Dir).to receive(:[]).and_return(%w(project.proj))
      allow(File).to receive(:read).and_return('<root></root>')
      allow(File).to receive(:open)
      allow(RakeFileUtils).to receive(:rm)
    }

    before {
      described_class.remove({
          projects: projects,
          references: references,
          specs: specs
        })
    }

    describe 'arguments' do
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

    context 'project unchanged' do
      let(:projects) { '**/*.??proj' }
      let(:references) { 'Reference' }
      let(:specs) { '*Specs.cs' }

      it 'should not write XML' do
        expect(File).not_to have_received(:open)
      end
    end
  end

  describe 'example' do
    let(:projects) { %w(**/*.??proj) }
    let(:references) { %w(Sample-Ref-1 Sample-Ref-2 Sample-Ref-3) }
    let(:specs) { %w(*Specs.cs **/*Specs.cs) }

    let(:temp_dir) { Dir.mktmpdir }

    before {
      FileUtils.cp_r(File.join(File.dirname(__FILE__), 'specs_remover/.'), temp_dir)
    }

    before {
      allow(RakeFileUtils).to receive(:rm)
    }

    before {
      Dir.chdir(temp_dir) do
        described_class.remove({
            projects: projects,
            references: references,
            specs: specs
          })
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
        expect(project_xml).not_to include('Sample-Ref-1', 'Sample-Ref-2', 'Sample-Ref-3')
      end

      it 'should remove spec files' do
        expect(project_xml).not_to include('Specs.cs', 'SampleSpecs.cs')
      end
    end
  end
end
