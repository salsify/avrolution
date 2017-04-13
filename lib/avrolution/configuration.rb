module Avrolution

  COMPATIBILITY_SCHEMA_REGISTRY_URL = 'COMPATIBILITY_SCHEMA_REGISTRY_URL'.freeze
  DEPLOYMENT_SCHEMA_REGISTRY_URL = 'DEPLOYMENT_SCHEMA_REGISTRY_URL'.freeze

  class << self
    # Root directory to search for schemas, and default location for
    # compatibility breaks file
    attr_writer :root

    # Path to the compatibility breaks file. Defaults to
    # #{Avrolution.root}/avro_compatibility_breaks.txt
    attr_writer :compatibility_breaks_file

    # The URL (including any Basic Auth) for the schema registry to use for
    # compatibility checks
    attr_writer :compatibility_schema_registry_url

    # The URL (including any Basic Auth) for the schema registry to use for
    # deployment
    attr_writer :deployment_schema_registry_url

    attr_accessor :logger
  end

  self.logger = Avrolution::PassthruLogger.new($stdout)

  def self.root
    @root || raise('root must be set')
  end

  def self.compatibility_breaks_file
    @compatibility_breaks_file ||= "#{root}/avro_compatibility_breaks.txt"
  end

  def self.compatibility_schema_registry_url
    @compatibility_schema_registry_url = @compatibility_schema_registry_url.call if @compatibility_schema_registry_url.is_a?(Proc)
    @compatibility_schema_registry_url ||= ENV.fetch(COMPATIBILITY_SCHEMA_REGISTRY_URL) do
      raise 'compatibility_schema_registry_url must be set'
    end
  end

  def self.deployment_schema_registry_url
    @deployment_schema_registry_url = @deployment_schema_registry_url.call if @deployment_schema_registry_url.is_a?(Proc)
    @deployment_schema_registry_url ||= ENV.fetch(DEPLOYMENT_SCHEMA_REGISTRY_URL) do
      raise 'deployment_schema_registry_url must be set'
    end
  end

  def self.configure
    yield self
  end
end
