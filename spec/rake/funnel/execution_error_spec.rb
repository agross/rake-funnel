describe Rake::Funnel::ExecutionError do
  its(:to_s) { should == described_class.to_s }

  context 'with command' do
    subject { described_class.new('command') }

    its(:command) { should == 'command' }
    its(:exit_code) { should be_nil }
    its(:output) { should be_nil }
    its(:description) { should be_nil }
    its(:to_s) { should =~ /^Error executing:\scommand/ }
  end

  context 'with command and exit code' do
    subject { described_class.new('command', 127) }

    its(:command) { should == 'command' }
    its(:exit_code) { should == 127 }
    its(:output) { should be_nil }
    its(:description) { should be_nil }
    its(:to_s) { should =~ /^Error executing:\scommand/ }
    its(:to_s) { should =~ /^Exit code: 127/ }
    end

  context 'with command and exit code and output' do
    subject { described_class.new('command', 127, 'output') }

    its(:command) { should == 'command' }
    its(:exit_code) { should == 127 }
    its(:output) { should == 'output' }
    its(:description) { should be_nil }
    its(:to_s) { should =~ /^Error executing:\scommand/ }
    its(:to_s) { should =~ /^Exit code: 127/ }
    its(:to_s) { should =~ /^Command output \(last 10 lines\):\soutput/ }
  end

  context 'with command and exit code and output and message' do
    subject { described_class.new('command', 127, 'output', 'description') }

    its(:command) { should == 'command' }
    its(:exit_code) { should == 127 }
    its(:output) { should == 'output' }
    its(:description) { should == 'description' }
    its(:to_s) { should =~ /^description/ }
    its(:to_s) { should =~ /^Error executing:\scommand/ }
    its(:to_s) { should =~ /^Exit code: 127/ }
    its(:to_s) { should =~ /^Command output \(last 10 lines\):\soutput/ }
  end

  context 'with output longer than 10 lines' do
    let(:output) {
      output = []

      11.times.each do |i|
        output << "output #{i}"
      end

      output.join("\n")
    }

    subject { described_class.new(nil, nil, output) }

    it 'should display the last 10 lines of output' do
      expect(subject.to_s).not_to match(/^output 0/)
    end
  end
end
