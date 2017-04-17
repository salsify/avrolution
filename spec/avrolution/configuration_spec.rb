describe Avrolution, "configuration" do
  describe "#compatibility_schema_registry_url" do
    let(:configured_value) { 'http://static.example.com' }

    subject(:url) do
      described_class.compatibility_schema_registry_url
    end

    before do
      Avrolution.compatibility_schema_registry_url = configured_value
    end

    it "returns the configured value" do
      expect(url).to eq(configured_value)
    end

    context "when the configured value is a Proc" do
      let(:dynamic_value) { 'http://dynamic.example.com' }
      let(:configured_value) do
        -> { dynamic_value }
      end

      it "returns the result of the proc" do
        expect(url).to eq(dynamic_value)
      end
    end

    context "when a value is not configured" do
      let(:configured_value) { nil }

      it "raises an error" do
        expect { url }.to raise_error('compatibility_schema_registry_url must be set')
      end
    end

    context "when the environment variable is set" do
      let(:env_value) { 'http://environment.example.com' }
      let(:env_var_name) { 'COMPATIBILITY_SCHEMA_REGISTRY_URL' }
      before do
        allow(ENV).to receive(:[]).with(env_var_name).and_return(env_value)
      end

      it "returns the environment value" do
        expect(url).to eq(env_value)
      end
    end
  end

  describe "#deployment_schema_registry_url" do
    let(:configured_value) { 'http://static.example.com' }

    subject(:url) do
      described_class.deployment_schema_registry_url
    end

    before do
      Avrolution.deployment_schema_registry_url = configured_value
    end

    it "returns the configured value" do
      expect(url).to eq(configured_value)
    end

    context "when the configured value is a Proc" do
      let(:dynamic_value) { 'http://dynamic.example.com' }
      let(:configured_value) do
        -> { dynamic_value }
      end

      it "returns the result of the proc" do
        expect(url).to eq(dynamic_value)
      end
    end

    context "when a value is not configured" do
      let(:configured_value) { nil }

      it "raises an error" do
        expect { url }.to raise_error('deployment_schema_registry_url must be set')
      end
    end

    context "when the environment variable is set" do
      let(:env_value) { 'http://environment.example.com' }
      let(:env_var_name) { 'DEPLOYMENT_SCHEMA_REGISTRY_URL' }

      before do
        allow(ENV).to receive(:[]).with(env_var_name).and_return(env_value)
      end

      it "returns the environment value" do
        expect(url).to eq(env_value)
      end
    end
  end
end
