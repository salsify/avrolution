describe Avrolution::RegisterSchemas, :fakefs do
  let(:schema_registry) { instance_double(AvroSchemaRegistry::Client) }
  let(:logger) { instance_double(Logger, info: nil) }
  let(:app_schema_path) { File.join(Avrolution.root, 'avro/schema') }
  let(:schema_files) { [] }
  let(:register_schemas) { described_class.new(schema_files) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('COMPATIBILITY_REGISTRY_URL').and_return('registry_url')
    allow(AvroSchemaRegistry::Client).to receive(:new).and_return(schema_registry)
    FileUtils.mkdir_p(app_schema_path)
  end

  describe "#call" do
    let(:app_schema_file) { File.join(app_schema_path, 'app.avsc') }
    let(:schema_files) { [app_schema_file] }
    let(:fingerprint) do
      Avro::Schema.parse(File.read(app_schema_file)).sha256_resolution_fingerprint.to_s(16)
    end
    let(:fullname) { 'com.salsify.app' }
    let(:json) do
      {
        type: :record,
        name: fullname,
        fields: [{ type: :string, name: :s, default: '' }]
      }.to_json
    end

    before do
      allow(schema_registry).to receive(:register_without_lookup)
      File.write(app_schema_file, json)
    end

    it "registers the specified schema file" do
      register_schemas.call
      expect(schema_registry).to have_received(:register_without_lookup)
        .with(fullname, json, {})
    end

    context "when the new schema is incompatible" do
      before do
        allow(schema_registry).to receive(:register_without_lookup).and_raise(Excon::Error::Conflict.new(409))
      end

      it "raises an error" do
        expect do
          register_schemas.call
        end.to raise_error(described_class::IncompatibleSchemaError, "incompatible schema #{fullname}")
      end
    end

    context "when a compatibility break is defined for a schema file" do
      let(:compatibility_breaks_file) { Avrolution::CompatibilityBreaksFile.path }
      let(:with_compatibility) { 'NONE' }
      let(:after_compatibility) { 'FULL' }

      before do
        FileUtils.mkdir_p(File.dirname(compatibility_breaks_file))
        File.write(compatibility_breaks_file, "#{fullname} #{fingerprint} #{with_compatibility} #{after_compatibility}\n")
      end

      it "registers the specified schema file" do
        register_schemas.call
        expect(schema_registry).to have_received(:register_without_lookup)
          .with(fullname, json, with_compatibility: with_compatibility, after_compatibility: after_compatibility)
      end
    end

    context "when a schema file does not exist" do
      let(:schema_files) { File.join(app_schema_path, '/does/not/exist.avsc') }

      it "does not raise an error" do
        expect do
          register_schemas.call
        end.not_to raise_error
      end
    end
  end

end
