module Avrolution

  COMPATIBILITY_SCHEMA_REGISTRY_URL = 'COMPATIBILITY_SCHEMA_REGISTRY_URL'.freeze

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

    attr_accessor :logger
  end

  @logger = Avrolution::PassthruLogger.new($stdout)

  def self.root
    raise('root must be set') unless @root
    @root
  end

  def self.compatibility_breaks_file
    @compatibility_breaks_file ||= "#{root}/avro_compatibility_breaks.txt"
  end

  def self.compatibility_schema_registry_url
    @compatibility_schema_registry_url ||= begin
      raise 'compatibility_schema_registry_url must be set' unless ENV[COMPATIBILITY_SCHEMA_REGISTRY_URL]
      ENV[COMPATIBILITY_SCHEMA_REGISTRY_URL]
    end
  end

  def self.configure
    yield self
  end
end
