$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'avrolution'

# pp must be required prior to fakefs/spec_helpers
require 'pp'
require 'fakefs/spec_helpers'
require 'rspec/its'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# FakeFS does not play well with locales lazy-loaded by I18n, so generate
# an error to pre-cache them.
# rubocop:disable Style/RescueModifier
Avrolution::CompatibilityBreak
  .new('', '', 'FOO', 'BAR')
  .validate! rescue nil
# rubocop:enable Style/RescueModifier

RSpec.configure do |config|
  config.before do
    Avrolution.root = '/schema_root'
    Avrolution.compatibility_schema_registry_url = 'https://compatibility.example.com'
    Avrolution.deployment_schema_registry_url = 'https://deployment.example.com'
  end

  config.include FakeFS::SpecHelpers, fakefs: true
end
