# frozen_string_literal: true

describe Avrolution::CompatibilityCheck, :fakefs do
  let(:schema_registry) { instance_double(AvroSchemaRegistry::Client) }
  let(:app_schema_path) { File.join(Avrolution.root, 'avro/schema') }
  let(:logger) { instance_double(Logger, info: nil) }
  let(:not_found_error) { Excon::Errors::NotFound.new('Not Found') }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('COMPATIBILITY_REGISTRY_URL').and_return('registry_url')
    allow(AvroSchemaRegistry::Client).to receive(:new).and_return(schema_registry)
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
    let(:new_json) do
      {
        type: :record,
        name: 'com.salsify.app',
        fields: [{ type: :string, name: :s, default: '' }]
      }.to_json
    end

    before do
      File.write(app_schema_file, new_json)
    end

    context "when there are schema files under vendor/bundle" do
      let(:app_schema_path) { File.join(Avrolution.root, 'vendor/bundle') }
      let(:new_json) { 'this is invalid json' }

      it "ignores schema files under vendor/bundle" do
        expect(check.call).to be_success
      end
    end

    context "when all schemas are compatible" do
      before do
        allow(schema_registry).to receive(:compatible?).and_return(true)
        allow(schema_registry).to receive(:lookup_subject_schema).and_raise(not_found_error)
      end

      it "returns success" do
        expect(check.call).to be_success
        expect(schema_registry).to have_received(:compatible?)
                                     .with('com.salsify.app', Avro::Schema, 'latest')
      end
    end

    context "when all schemas are already registered" do
      let(:id) { rand(1..100) }

      before do
        allow(schema_registry).to receive(:lookup_subject_schema).and_return(id)
      end

      it "returns success" do
        expect(check.call).to be_success
        expect(schema_registry).to have_received(:lookup_subject_schema)
                                     .with('com.salsify.app', Avro::Schema)
      end
    end

    shared_examples_for "an incompatible schema" do
      let(:old_json) do
        # no field default
        {
          type: :record,
          name: 'com.salsify.app',
          fields: [{ type: :int, name: :i }]
        }.to_json
      end
      let(:actual_compatibility) { 'BACKWARD' }
      let(:config_compatibility) { 'BOTH' }
      let(:reported_config_compatibility) { 'FULL' }

      before do
        allow(schema_registry).to receive(:lookup_subject_schema).and_raise(not_found_error)
        allow(schema_registry).to receive(:subject_version).and_return('schema' => old_json)
        allow(schema_registry).to receive(:subject_config).and_return('compatibility' => config_compatibility)
      end

      it "returns failure", :aggregate_failures do
        expect(check.call).not_to be_success
        expect(check.incompatible_schemas).to eq([app_schema_file])

        expect(logger).to have_received(:info).with(/Compatibility with last version: #{actual_compatibility}/)
        expect(logger).to have_received(:info).with(/Current compatibility level: #{reported_config_compatibility}/)
        expect(logger).to have_received(:info).with(
          /rake avro:add_compatibility_break name=com\.salsify\.app fingerprint=#{fingerprint} with_compatibility=#{actual_compatibility}/ # rubocop:disable Layout/LineLength
        )
      end
    end

    context "when there is an incompatible schema" do
      before do
        allow(schema_registry).to receive(:compatible?).and_return(false)
      end

      it_behaves_like "an incompatible schema"

      it_behaves_like "an incompatible schema" do
        let(:actual_compatibility) { 'FORWARD' }
        let(:old_json) do
          # has field default
          {
            type: :record,
            name: 'com.salsify.app',
            fields: [{ type: :int, name: :i, default: 0 }]
          }.to_json
        end
        let(:new_json) do
          # no field default
          {
            type: :record,
            name: 'com.salsify.app',
            fields: [{ type: :string, name: :s }]
          }.to_json
        end
      end

      it_behaves_like "an incompatible schema" do
        let(:config_compatibility) { 'FULL_TRANSITIVE' }
        let(:actual_compatibility) { 'FULL' }
        let(:old_json) do
          # has field default
          {
            type: :record,
            name: 'com.salsify.app',
            fields: [{ type: :int, name: :i, default: 0 }]
          }.to_json
        end
        let(:new_json) do
          # has field default
          {
            type: :record,
            name: 'com.salsify.app',
            fields: [{ type: :string, name: :s, default: '' }]
          }.to_json
        end
      end
    end

    context "when there is an incompatible schema with a compatibility break defined" do
      let(:compatibility_breaks_file) { Avrolution::CompatibilityBreaksFile.path }
      let(:with_compatibility) { 'NONE' }

      before do
        allow(schema_registry).to receive(:lookup_subject_schema).and_return(not_found_error)
        allow(schema_registry).to receive(:compatible?).with('com.salsify.app', Avro::Schema, 'latest')
                                                       .and_return(false)
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
