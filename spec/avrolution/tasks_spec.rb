# frozen_string_literal: true

describe "rake tasks" do
  include_context "rake setup"

  let(:task_path) { 'avrolution/rake/rails_avrolution' }

  describe "register_schemas" do
    let(:task_name) { 'avro:register_schemas' }
    let(:schema_files) { ['app.avsc'] }
    let(:register_schemas) { Avrolution::RegisterSchemas.new(schema_files) }

    before do
      @original_schemas = ENV['schemas']
      ENV['schemas'] = schema_files.join(',')
      allow(Avrolution::RegisterSchemas).to receive(:new).and_return(register_schemas)
      allow(register_schemas).to receive(:call).and_call_original
    end

    after do
      ENV['schemas'] = @original_schemas
    end

    it "dispatches to a RegisterSchemas instance" do
      task.invoke

      expect(register_schemas).to have_received(:call)
    end
  end

  describe "register_all_schemas" do
    let(:task_name) { 'avro:register_all_schemas' }
    let(:schema_files) { Avrolution::DiscoverSchemas.discover(Dir.pwd) }
    let(:register_schemas) { instance_spy(Avrolution::RegisterSchemas) }

    before do
      allow(Avrolution::RegisterSchemas).to receive(:new).and_return(register_schemas)
      allow(Avrolution::DiscoverSchemas).to receive(:discover).and_return(schema_files)
    end

    it "dispatches to a RegisterSchemas instance" do
      task.invoke

      expect(register_schemas).to have_received(:call)
    end
  end

  describe "check_compatibility" do
    let(:task_name) { 'avro:check_compatibility' }
    let(:compatibility_check) { Avrolution::CompatibilityCheck.new }

    before do
      allow(Avrolution::CompatibilityCheck).to receive(:new).and_return(compatibility_check)
      allow(compatibility_check).to receive(:call).and_call_original
    end

    it "dispatches to a CompatibilityCheck instance" do
      task.invoke

      expect(compatibility_check).to have_received(:call)
    end
  end

  describe "add_compatibility_break" do
    let(:task_name) { 'avro:add_compatibility_break' }

    before do
      allow(Avrolution::CompatibilityBreaksFile).to receive(:add)
      @original_name = ENV['name']
      ENV['name'] = 'test-name'
      @original_fingerprint = ENV['fingerprint']
      ENV['fingerprint'] = 'test-fingerprint'
    end

    after do
      ENV['name'] = @original_name
      ENV['fingerprint'] = @original_fingerprint
    end

    it "adds a compatibility break entry" do
      task.invoke

      expect(Avrolution::CompatibilityBreaksFile).to have_received(:add)
    end
  end
end
