# frozen_string_literal: true

describe Rake::Funnel::Tasks::Zip do
  before do
    Rake::Task.clear
  end

  describe 'defaults' do
    its(:name) { should == :package }
    its(:source) { should eq([]) }
    its(:target) { should be_nil }
    its(:zip_root) { should be_nil }
    its(:allow_empty) { should eq(true) }
  end

  describe 'execution' do
    let(:source) { %w(bin/1 bin/2 bin/3/4) }
    let(:finder) { instance_double(Rake::Funnel::Support::Finder).as_null_object }

    before do
      allow(finder).to receive(:all_or_default).and_return(source)
      allow(Rake::Funnel::Support::Finder).to receive(:new).and_return(finder)
    end

    before do
      allow(Rake::Funnel::Support::Zipper).to receive(:zip)
      allow($stderr).to receive(:print)
    end

    subject do
      described_class.new do |t|
        t.source = source
        t.target = 'some path/file.zip'
        t.zip_root = 'zip root'
      end
    end

    before do
      Rake::Task[subject.name].invoke
    end

    it 'should delegate to Zipper' do
      expect(Rake::Funnel::Support::Zipper).to have_received(:zip)
        .with(subject.source, subject.target, subject.zip_root)
    end

    it 'should report the created zip file' do
      expect($stderr).to have_received(:print).with("Created #{subject.target}\n")
    end

    describe '#allow_empty' do
      subject do
        described_class.new do |t|
          t.source = source
          t.target = 'some path/file.zip'
          t.zip_root = 'zip root'
          t.allow_empty = allow_empty
        end
      end

      context 'empty allowed with empty file list' do
        let(:source) { [] }
        let(:allow_empty) { true }

        before do
          Rake::Task[subject.name].invoke
        end

        it 'should invoker Zipper' do
          expect(Rake::Funnel::Support::Zipper).to have_received(:zip)
        end
      end

      context 'empty not allowed with empty file list' do
        let(:source) { [] }
        let(:allow_empty) { false }

        before do
          Rake::Task[subject.name].invoke
        end

        it 'should not invoker Zipper' do
          expect(Rake::Funnel::Support::Zipper).not_to have_received(:zip)
        end

        it 'should warn' do
          expect($stderr).to have_received(:print).with("No files to zip\n")
        end
      end
    end
  end
end
