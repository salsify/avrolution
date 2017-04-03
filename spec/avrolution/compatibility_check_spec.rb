describe Avrolution::CompatibilityCheck, :fakefs do
  include_context "Rails context"

  let(:schema_registry) { instance_double(AvroTurf::ConfluentSchemaRegistry) }
  let(:app_schema_path) { File.join(Rails.root, 'avro/schema') }
  let(:gem_schema_path) { File.join(Rails.root, 'schemas_gem/avro/schema') }
  let(:logger) { instance_double(Logger, info: nil) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('COMPATIBILITY_REGISTRY_URL').and_return('registry_url')
    allow(AvroTurf::ConfluentSchemaRegistry).to receive(:new).and_return(schema_registry)
    FileUtils.mkdir_p(app_schema_path)
    # Diffy uses the tmp directory
    FileUtils.mkdir('/tmp')
  end

  subject(:check) { described_class.new(logger: logger) }

  describe "#call" do
    let(:app_schema_file) { File.join(app_schema_path, 'app.avsc') }
    let(:fingerprint) do
      Avro::Schema.parse(File.read(app_schema_file)).sha256_resolution_fingerprint.to_s(16)
    end

    before do
      File.write(app_schema_file, <<-JSON)
{ "type": "record", "name": "com.salsify.app" }
      JSON
    end

    context "when all schemas are compatible" do
      before do
        allow(schema_registry).to receive(:compatible?).and_return(true)
      end

      it "returns success" do
        expect(check.call).to be_success
        expect(schema_registry).to have_received(:compatible?)
                                     .with('com.salsify.app', Avro::Schema, 'latest')
      end

      context "when there is a schemas_gem directory" do
        before do
          FileUtils.mkdir_p(gem_schema_path)
          File.write(File.join(gem_schema_path, 'gem.avsc'), <<-JSON)
{ "type": "record", "name": "com.salsify.gem" }
          JSON
        end

        it "returns success" do
          expect(check.call).to be_success
          expect(schema_registry).to have_received(:compatible?).twice
        end
      end
    end

    shared_examples_for "an incompatible schema" do
      let(:old_version) do <<-JSON
{ "type": "record", "name": "com.salsify.app", "fields": [{ "type": "int", "name": "i" }] }
      JSON
      end

      before do
        allow(schema_registry).to receive(:subject_version).and_return('schema' => old_version)
        allow(schema_registry).to receive(:subject_config).and_return('compatibility' => 'FULL')
      end

      it "returns failure", :aggregate_failures do
        expect(check.call).not_to be_success
        expect(check.incompatible_schemas).to eq([app_schema_file])

        expect(logger).to have_received(:info).with(/Compatibility with last version: FORWARD/)
        expect(logger).to have_received(:info).with(/Current compatibility level: FULL/)
        expect(logger).to have_received(:info)
                            .with(/rake avro:add_compatibility_break name=com\.salsify\.app fingerprint=#{fingerprint} with_compatibility=FORWARD/)
      end
    end

    context "when there is an incompatible schema" do

      before do
        allow(schema_registry).to receive(:compatible?).and_return(false)
      end

      it_behaves_like "an incompatible schema"
    end

    context "when there is an incompatible schema with a compatibility break defined" do
      let(:compatibility_breaks_file) { Avrolution::CompatibilityBreaksFile.path }
      let(:with_compatibility) { 'NONE' }

      before do
        allow(schema_registry).to receive(:compatible?).with('com.salsify.app', Avro::Schema, 'latest').and_return(false)
        FileUtils.mkdir_p(File.dirname(compatibility_breaks_file))
        File.write(compatibility_breaks_file, "com.salsify.app #{fingerprint} #{with_compatibility}\n")
      end

      context "when the schema is compatible using the defined compatibility break" do
        before do
          allow(schema_registry).to receive(:compatible?)
                                      .with('com.salsify.app', Avro::Schema, 'latest', with_compatibility: with_compatibility).and_return(true)
        end

        it "returns success" do
          expect(check.call).to be_success
        end
      end

      context "when the schema is still incompatible using the compatibility break" do
        let(:with_compatibility) { 'FORWARD' }

        before do
          allow(schema_registry).to receive(:compatible?)
                                      .with('com.salsify.app', Avro::Schema, 'latest', with_compatibility: with_compatibility).and_return(false)
        end

        it_behaves_like "an incompatible schema"
      end
    end
  end
end
