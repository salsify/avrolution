module Avrolution

  COMPATIBILITY = 'compatibility'.freeze
  DEPLOYMENT = 'deployment'.freeze

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

    def fetch_url(label)
      env_name = "#{label.upcase}_SCHEMA_REGISTRY_URL"
      ivar_name = "@#{env_name.downcase}"
      env_value = ENV[env_name]
      result = if env_value
                 env_value
               elsif instance_variable_get(ivar_name)
                 ivar_value = instance_variable_get(ivar_name)
                 ivar_value = instance_variable_set(ivar_name, ivar_value.call) if ivar_value.is_a?(Proc)
                 ivar_value
               end

      raise "#{env_name.downcase} must be set" if result.blank?
      result
    end
  end

  self.logger = Avrolution::PassthruLogger.new($stdout)

  def self.root
    @root || raise('root must be set')
  end

  def self.compatibility_breaks_file
    @compatibility_breaks_file ||= "#{root}/avro_compatibility_breaks.txt"
  end

  def self.compatibility_schema_registry_url
    fetch_url(COMPATIBILITY)
  end

  def self.deployment_schema_registry_url
    fetch_url(DEPLOYMENT)
  end

  def self.configure
    yield self
  end
end
