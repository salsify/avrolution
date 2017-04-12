describe Avrolution::CompatibilityBreak do
  let(:name) { 'com.example.test' }
  let(:fingerprint) do
    Avro::Schema.parse({ name: name, type: :record }.to_json).sha256_resolution_fingerprint.to_s(16)
  end

  context "validation" do
    let(:with_compatibility) { 'NONE' }
    let(:after_compatibility) { nil }

    subject { described_class.new(name, fingerprint, with_compatibility, after_compatibility) }

    context "when name is blank" do
      let(:name) { '' }

      it { is_expected.to be_invalid }
    end

    context "when fingerprint is blank" do
      let(:fingerprint) { nil }

      it { is_expected.to be_invalid }
    end

    context "when with_compatibility does not have a valid value" do
      let(:with_compatibility) { 'FOO' }

      it { is_expected.to be_invalid }
    end

    context "when after_compatibility does not have a valid value" do
      let(:after_compatibility) { 'BAR' }

      it { is_expected.to be_invalid }
    end
  end

  describe "#validate!" do
    let(:with_compatibility) { 'NONE' }
    let(:after_compatibility) { nil }
    let(:compatibility_break) do
      described_class.new(name, fingerprint, with_compatibility, after_compatibility)
    end

    context "when the compatibility break is valid" do
      it "returns nil" do
        expect(compatibility_break.validate!).to be_nil
      end
    end

    context "when the compatibility break is invalid" do
      subject(:compatibility_break) do
        described_class.new(nil, '', 'FOO', 'BAR')
      end

      it "raises an error with the validation messages" do
        expect do
          compatibility_break.validate!
        end.to raise_error(described_class::ValidationError,
                           "Name can't be blank, Fingerprint can't be blank, "\
                           'With compatibility is not included in the list, '\
                           'After compatibility is not included in the list')
      end
    end

  end

  describe "#key" do
    subject { described_class.new(name, fingerprint) }

    its(:key) { is_expected.to eq([name, fingerprint]) }
  end

  describe "#line" do
    let(:with_compatibility) { 'FORWARD' }

    subject { described_class.new(name, fingerprint, with_compatibility) }

    its(:line) { is_expected.to eq("#{name} #{fingerprint} #{with_compatibility}") }

    context "when after_compatibility is set" do
      let(:with_compatibility) { 'NONE' }
      let(:after_compatibility) { 'BACKWARD' }

      subject { described_class.new(name, fingerprint, with_compatibility, after_compatibility) }

      its(:line) { is_expected.to eq("#{name} #{fingerprint} #{with_compatibility} #{after_compatibility}") }
    end
  end

  describe "#register_options" do
    let(:with_compatibility) { 'FULL' }

    subject { described_class.new(name, fingerprint, with_compatibility) }

    its(:register_options) { is_expected.to eq(with_compatibility: with_compatibility) }

    context "when after_compatibility is set" do
      let(:with_compatibility) { 'NONE' }
      let(:after_compatibility) { 'BACKWARD' }

      subject { described_class.new(name, fingerprint, with_compatibility, after_compatibility) }

      its(:register_options) { is_expected.to eq(with_compatibility: with_compatibility, after_compatibility: after_compatibility) }
    end
  end
end
