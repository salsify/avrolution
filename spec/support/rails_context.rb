shared_context "Rails context" do
  let(:rails_mock) { double('Rails') } # rubocop:disable RSpec/VerifiedDoubles
  let(:rails_root) { '/rails_root' }
  let(:logger) { instance_double(Logger) }

  before do
    stub_const('Rails', rails_mock)
    allow(rails_mock).to receive(:root).and_return(rails_root)
    allow(rails_mock).to receive(:logger).and_return(logger)
  end
end
