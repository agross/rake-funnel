describe Rake::Funnel::Support::TemplateEngine do
  it 'should render nil' do
    expect(described_class.render(nil)).to eq('')
  end

  it 'should render empty string' do
    expect(described_class.render('')).to eq('')
  end

  it 'should static string' do
    expect(described_class.render('hello world')).to eq('hello world')
  end

  it 'should support ruby' do
    expect(described_class.render('<%= 42 %>')).to eq('42')
  end

  it 'should omit newlines for pure ruby lines' do
    template = <<-EOF
<%= 42 %>
    EOF

    expect(described_class.render(template)).to eq('42')
  end

  it 'should not omit newlines for mixed ruby lines' do
    template = <<-EOF
12 <%= 34 %> 56
    EOF

    expect(described_class.render(template)).to eq("12 34 56\n")
  end

  it 'should support @ instead of <%= %>' do
    expect(described_class.render('@String.to_s@')).to eq('String')
  end

  describe 'binding' do
    context 'without binding' do
      it 'should not support contextual variables' do
        var = 42
        template = '<%= var %>'

        expect { described_class.render(template) }.to raise_error(NameError)
      end
    end

    context 'with binding' do
      def get_binding(value)
        binding
      end

      it 'should support contextual variables with binding' do
        template = '<%= value %>'

        expect(described_class.render(template, nil, get_binding(42))).to eq('42')
      end
    end
  end

  it 'should report errors with file name' do
    expect { described_class.render('<%= undefined %>', 'file.template') }
      .to raise_error { |ex| expect(ex.backtrace.join("\n")).to match(/file\.template/) }
  end
end
