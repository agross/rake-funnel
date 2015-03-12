require 'ostruct'
require 'tmpdir'

describe Rake::Funnel::Support::VersionInfo do
  describe '#parse' do
    [
      {
        context: {
          version: '1.2',
          build_number: '42',
          sha: 'sha'
        },
        expected: {
          assembly_version: '1.2',
          assembly_file_version: '1.2.42',
          assembly_informational_version: '1.2.42-sha'
        }
      },
      {
        context: {
          version: '1.2-pre1',
          build_number: '42',
          sha: 'sha'
        },
        expected: {
          assembly_version: '1.2',
          assembly_file_version: '1.2.42',
          assembly_informational_version: '1.2-pre1.42-sha'
        }
      },
      {
        context: {
          version: '1.2.3',
          build_number: '42',
          sha: 'sha' },
        expected: {
          assembly_version: '1.2.3',
          assembly_file_version: '1.2.3.42',
          assembly_informational_version: '1.2.3.42-sha'
        }
      },
      {
        context: {
          version: '1.2.3-pre1',
          build_number: '42',
          sha: 'sha'
        },
        expected: {
          assembly_version: '1.2.3',
          assembly_file_version: '1.2.3.42',
          assembly_informational_version: '1.2.3-pre1.42-sha'
        }
      },
      {
        context: {
          version: '1.2',
          build_number: '-pre',
          sha: 'sha'
        },
        expected: {
          assembly_version: '1.2',
          assembly_file_version: '1.2',
          assembly_informational_version: '1.2-pre-sha'
        }
      },
      {
        context: {
          version: '1.2',
          build_number: '-pre42',
          sha: 'sha'
        },
        expected: {
          assembly_version: '1.2',
          assembly_file_version: '1.2.42',
          assembly_informational_version: '1.2-pre42-sha'
        }
      },
      {
        context: {
          version: '1.2',
          build_number: nil,
          sha: nil
        },
        expected: {
          assembly_version: '1.2',
          assembly_file_version: '1.2',
          assembly_informational_version: '1.2'
        }
      },
      {
        context: {
          version: '1.2',
          build_number: '42',
          sha: nil
        },
        expected: {
          assembly_version: '1.2',
          assembly_file_version: '1.2.42',
          assembly_informational_version: '1.2.42'
        }
      },
      {
        context: {
          version: 1,
          build_number: '42',
          sha: 'sha'
        },
        expected: {
          assembly_version: '1',
          assembly_file_version: '1.42',
          assembly_informational_version: '1.42-sha'
        }
      },
      {
        context: {
          version: '1.2',
          build_number: 42,
          sha: 'sha'
        },
        expected: {
          assembly_version: '1.2',
          assembly_file_version: '1.2.42',
          assembly_informational_version: '1.2.42-sha'
        }
      },
      {
        context: {
          version: '1.2'
        },
        expected: {
          assembly_version: '1.2',
          assembly_file_version: '1.2',
          assembly_informational_version: '1.2'
        }
      },
      {
        context: {
          version: nil,
          build_number: nil,
          sha: nil
        },
        expected: {
          assembly_version: '0',
          assembly_file_version: '0',
          assembly_informational_version: '0'
        }
      },
      {
        context: {},
        expected: {
          assembly_version: '0',
          assembly_file_version: '0',
          assembly_informational_version: '0'
        }
      }
    ].each do |spec|
      context "version #{spec[:context][:version] || 'none'}, build number #{spec[:context][:build_number] || 'none'}, SHA #{spec[:context][:sha] || 'none'}" do
        let(:parsed) { described_class.parse(spec[:context]) }

        it "should generate assembly version #{spec[:expected][:assembly_version]}" do
          expect(parsed.assembly_version).to eq(spec[:expected][:assembly_version])
        end

        it "should generate assembly file version #{spec[:expected][:assembly_file_version]}" do
          expect(parsed.assembly_file_version).to eq(spec[:expected][:assembly_file_version])
        end

        it "should generate assembly informational version #{spec[:expected][:assembly_informational_version]}" do
          expect(parsed.assembly_informational_version).to eq(spec[:expected][:assembly_informational_version])
        end
      end
    end
  end

  describe 'enumerable' do
    it 'should be enumerable' do
      expect(described_class < Enumerable).to eq(true)
      expect(subject.respond_to?(:each)).to eq(true)
      expect(subject.each).to be_kind_of(Enumerator)
    end

    context 'enumerating' do
      let(:args) { { a: 42, b: 23 } }

      subject { described_class.new(args) }

      it 'should yield all hash pairs' do
        expect { |b| subject.each(&b) }.to yield_successive_args([:a, 42], [:b, 23])
      end
    end
  end

  describe 'automatic methods' do
    it 'should be an OpenStruct' do
      expect(described_class < OpenStruct).to eq(true)
    end

    describe 'immutability' do
      let(:args) { { a: 42 } }

      subject { described_class.new(args) }

      it 'should be immutable' do
        expect { subject.a = 23 }.to raise_error
      end
    end
  end

  describe '#read_version_from' do
    let(:file) { 'file with version info' }
    let(:contents) { <<-EOF
  first line with expected version number
other crap
    EOF
    }

    it 'should read the first line with leading and trailing whitespace removed' do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do

          File.write(file, contents)
          expect(described_class.read_version_from(file)).to eq('first line with expected version number')
        end
      end
    end
  end
end
