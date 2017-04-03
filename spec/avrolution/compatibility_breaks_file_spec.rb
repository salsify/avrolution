describe SalsifyAvro::Compatibility::CompatibilityBreaksFile, :fakefs do
  include_context "Rails context"

  let(:logger) { instance_double(Logger, info: nil) }

  before do
    FileUtils.mkdir_p(File.dirname(described_class.path))
  end

  describe "self.path" do
    it "returns the path to the compatibility breaks file" do
      expect(described_class.path).to eq('/rails_root/avro/schema/compatibility_breaks.txt')
    end
  end

  describe "self.add" do
    let(:name) { 'com.salsify.foo' }
    let(:fingerprint) { 'ABC123' }
    let(:with_compatibility) { 'FORWARD' }
    let(:after_compatibility) { 'FULL' }

    context "validation" do
      it "raises an error when name is blank" do
        expect do
          described_class.add(name: '', fingerprint: fingerprint)
        end.to raise_error(SalsifyAvro::Compatibility::CompatibilityBreak::ValidationError, "Name can't be blank")
      end

      it "raises an error when fingerprint is blank" do
        expect do
          described_class.add(name: name, fingerprint: '')
        end.to raise_error(SalsifyAvro::Compatibility::CompatibilityBreak::ValidationError, "Fingerprint can't be blank")
      end

      it "raises an error when with compatibility is invalid" do
        expect do
          described_class.add(name: name, fingerprint: fingerprint, with_compatibility: 'FOO')
        end.to raise_error(SalsifyAvro::Compatibility::CompatibilityBreak::ValidationError, 'With compatibility is not included in the list')
      end

      it "raises an error when after compatibility is invalid" do
        expect do
          described_class.add(name: name, fingerprint: fingerprint, after_compatibility: 'FOO')
        end.to raise_error(SalsifyAvro::Compatibility::CompatibilityBreak::ValidationError, 'After compatibility is not included in the list')
      end
    end

    it "adds a line to the compatibility breaks file" do
      described_class.add(name: name, fingerprint: fingerprint, with_compatibility: with_compatibility, logger: logger)
      expect(File.read(described_class.path)).to eq("#{name} #{fingerprint} #{with_compatibility}\n")
    end

    context "when with_compatibility is not specified" do
      it "defaults with_compatibility to NONE" do
        described_class.add(name: name, fingerprint: fingerprint, logger: logger)
        expect(File.read(described_class.path)).to eq("#{name} #{fingerprint} NONE\n")
      end
    end

    context "when after compatibility is included" do
      it "adds a line to the compatibility breaks file" do
        described_class.add(name: name,
                            fingerprint: fingerprint,
                            with_compatibility: with_compatibility,
                            after_compatibility: after_compatibility,
                            logger: logger)
        expect(File.read(described_class.path)).to eq("#{name} #{fingerprint} #{with_compatibility} #{after_compatibility}\n")
      end
    end

    context "when the line to be added duplicates an existing entry" do
      let(:file_contents) do <<-TEXT
com.salsify.foo ABC123 BACKWARD
      TEXT
      end

      before do
        File.write(described_class.path, file_contents)
      end

      it "raises an error" do
        expect do
          described_class.add(name: name, fingerprint: fingerprint, logger: logger)
        end.to raise_error(described_class::DuplicateEntryError)
      end
    end
  end

  describe "self.load" do
    subject(:compatibility_breaks) { described_class.load }

    context "when the file does not exist" do
      it "returns an empty hash", :aggregate_failures do
        expect(compatibility_breaks).to be_a(Hash)
        expect(compatibility_breaks).to be_empty
      end
    end

    context "when the file exists" do
      let(:key) { %w(com.salsify.foo ABC123) }
      let(:file_contents) do <<-TEXT
# ignore me

com.salsify.foo ABC123 BACKWARD
com.salsify.bar XYZ456 NONE FULL
      TEXT
      end

      before do
        File.write(described_class.path, file_contents)
      end

      it "loads the entries" do
        expect(compatibility_breaks).to have_key(key)
      end

      context "when the file contains invalid entries" do
        let(:file_contents) do <<-TEXT
ONE TWO THREE FOUR
        TEXT
        end

        it "raises an error" do
          expect do
            compatibility_breaks
          end.to raise_error(SalsifyAvro::Compatibility::CompatibilityBreak::ValidationError)
        end
      end

      context "when the file contains duplicate entries" do
        let(:file_contents) do <<-TEXT
com.salsify.foo ABC123 BACKWARD
com.salsify.foo ABC123 FORWARD
        TEXT
        end

        it "raises an error" do
          expect do
            compatibility_breaks
          end.to raise_error(described_class::DuplicateEntryError, "duplicate entry for key #{key}")
        end
      end
    end
  end
end
