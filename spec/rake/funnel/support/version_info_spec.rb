# frozen_string_literal: true

require 'ostruct'
require 'tmpdir'

describe Rake::Funnel::Support::VersionInfo do
  describe '#parse' do
    [
      {
        context: {
          version: '1',
          metadata: {
            pre: 'alpha',
            build: '42',
            sha: '123'
          }
        },
        expected: {
          assembly_version: '1.0.0.0',
          assembly_file_version: '1.0.0.42',
          assembly_informational_version: '1.0.0-alpha+build.42.sha.123'
        }
      },
      {
        context: {
          version: '1.2',
          metadata: {
            pre: 'alpha',
            build: '42',
            sha: '123'
          }
        },
        expected: {
          assembly_version: '1.2.0.0',
          assembly_file_version: '1.2.0.42',
          assembly_informational_version: '1.2.0-alpha+build.42.sha.123'
        }
      },
      {
        context: {
          version: '1.2.3',
          metadata: {
            pre: 'alpha',
            build: '42',
            sha: '123'
          }
        },
        expected: {
          assembly_version: '1.2.3.0',
          assembly_file_version: '1.2.3.42',
          assembly_informational_version: '1.2.3-alpha+build.42.sha.123'
        }
      },
      {
        context: {
          version: '1.2.3.4',
          metadata: {
            pre: 'alpha',
            build: '42',
            sha: '123'
          }
        },
        expected: {
          assembly_version: '1.2.3.4',
          assembly_file_version: '1.2.3.4',
          assembly_informational_version: '1.2.3-alpha+build.42.sha.123'
        }
      },
      {
        context: {
          version: '-pre1',
          metadata: {
            pre: 'alpha',
            build: '42',
            sha: '123'
          }
        },
        expected: {
          assembly_version: '0.0.0.0',
          assembly_file_version: '0.0.0.42',
          assembly_informational_version: '0.0.0-pre1-alpha+build.42.sha.123'
        }
      },
      {
        context: {
          version: '1-pre1',
          metadata: {
            pre: 'alpha',
            build: '42',
            sha: '123'
          }
        },
        expected: {
          assembly_version: '1.0.0.0',
          assembly_file_version: '1.0.0.42',
          assembly_informational_version: '1.0.0-pre1-alpha+build.42.sha.123'
        }
      },
      {
        context: {
          version: '1.2-pre1',
          metadata: {
            pre: 'alpha',
            build: '42',
            sha: '123'
          }
        },
        expected: {
          assembly_version: '1.2.0.0',
          assembly_file_version: '1.2.0.42',
          assembly_informational_version: '1.2.0-pre1-alpha+build.42.sha.123'
        }
      },
      {
        context: {
          version: '1.2.3-pre1',
          metadata: {
            pre: 'alpha',
            build: '42',
            sha: '123'
          }
        },
        expected: {
          assembly_version: '1.2.3.0',
          assembly_file_version: '1.2.3.42',
          assembly_informational_version: '1.2.3-pre1-alpha+build.42.sha.123'
        }
      },
      {
        context: {
          version: '1.2.3.4-pre1',
          metadata: {
            pre: 'alpha',
            build: '42',
            sha: '123'
          }
        },
        expected: {
          assembly_version: '1.2.3.4',
          assembly_file_version: '1.2.3.4',
          assembly_informational_version: '1.2.3-pre1-alpha+build.42.sha.123'
        }
      },
      {
        context: {},
        expected: {
          assembly_version: '0.0.0.0',
          assembly_file_version: '0.0.0.0',
          assembly_informational_version: '0.0.0'
        }
      },
      {
        context: {
          metadata: {}
        },
        expected: {
          assembly_version: '0.0.0.0',
          assembly_file_version: '0.0.0.0',
          assembly_informational_version: '0.0.0'
        }
      },
      {
        context: {
          version: nil,
          metadata: {
            pre: nil,
            build: nil,
            sha: nil
          }
        },
        expected: {
          assembly_version: '0.0.0.0',
          assembly_file_version: '0.0.0.0',
          assembly_informational_version: '0.0.0'
        }
      },
      {
        context: {
          version: '1.2',
          metadata: {}
        },
        expected: {
          assembly_version: '1.2.0.0',
          assembly_file_version: '1.2.0.0',
          assembly_informational_version: '1.2.0'
        }
      },
      {
        context: {
          version: '1.2',
          metadata: {
            pre: nil,
            build: nil,
            sha: nil
          }
        },
        expected: {
          assembly_version: '1.2.0.0',
          assembly_file_version: '1.2.0.0',
          assembly_informational_version: '1.2.0'
        }
      },
      {
        context: {
          version: '1.2',
          metadata: {
            pre: 'alpha',
            build: nil,
            sha: nil
          }
        },
        expected: {
          assembly_version: '1.2.0.0',
          assembly_file_version: '1.2.0.0',
          assembly_informational_version: '1.2.0-alpha'
        }
      },
      {
        context: {
          version: '1.2',
          metadata: {
            pre: nil,
            build: '42',
            sha: nil
          }
        },
        expected: {
          assembly_version: '1.2.0.0',
          assembly_file_version: '1.2.0.42',
          assembly_informational_version: '1.2.0+build.42'
        }
      },
      {
        context: {
          version: '1.2',
          metadata: {
            pre: nil,
            build: nil,
            sha: '123'
          }
        },
        expected: {
          assembly_version: '1.2.0.0',
          assembly_file_version: '1.2.0.0',
          assembly_informational_version: '1.2.0+sha.123'
        }
      },
      {
        context: {
          version: 1,
          metadata: {
            pre: 123,
            build: 456,
            sha: 789
          }
        },
        expected: {
          assembly_version: '1.0.0.0',
          assembly_file_version: '1.0.0.456',
          assembly_informational_version: '1.0.0-123+build.456.sha.789'
        }
      }
    ].each do |spec|
      context "version #{spec[:context][:version] || 'none'}, build number #{spec[:context].fetch(:metadata, {})[:build] || 'none'}, SHA #{spec[:context].fetch(:metadata, {})[:sha] || 'none'}" do # rubocop:disable Metrics/LineLength
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
    it { is_expected.to be_kind_of(Enumerable) }
    it { is_expected.to respond_to(:each) }

    it 'should yield enumerator' do
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
  end

  describe '#read_version_from' do
    let(:file) { 'file with version info' }
    let(:contents) do
      # rubocop:disable Layout/IndentHeredoc
      <<-CONTENTS
  first line with expected version number
other crap
      CONTENTS
      # rubocop:enable Layout/IndentHeredoc
    end

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
