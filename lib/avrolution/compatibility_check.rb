require 'private_attr'
require 'netrc'
require 'diffy'
require 'avromatic'

module Avrolution
  class CompatibilityCheck
    extend PrivateAttr

    attr_reader :incompatible_schemas

    NONE = 'NONE'.freeze
    FULL = 'FULL'.freeze
    BACKWARD = 'BACKWARD'.freeze
    FORWARD = 'FORWARD'.freeze

    private_attr_reader :schema_registry, :compatibility_breaks,
                        :logger

    def initialize(logger: Avrolution::PassthruLogger.new($stdout))
      @incompatible_schemas = []
      @schema_registry = build_schema_registry
      @compatibility_breaks = Avrolution::CompatibilityBreaksFile.load
      @logger = logger
    end

    def call
      roots.each { |path| check_schemas(path) }
      self
    end

    def success?
      incompatible_schemas.empty?
    end

    private

    def check_schemas(path)
      Dir[File.join(path, '**/*.avsc')].each do |schema_file|
        check_schema_compatibility(schema_file)
      end
    end

    def check_schema_compatibility(file)
      schema = Avro::Schema.parse(File.read(file))
      return unless schema.type_sym == :record

      fullname = schema.fullname
      fingerprint = schema.sha256_resolution_fingerprint.to_s(16)

      logger.info("Checking compatibility: #{fullname}")
      compatible = schema_registry.compatible?(fullname, schema, 'latest')

      if compatible.nil?
        # compatible is nil if the subject is not registered
        logger.info("... New schema: #{fullname}")
      elsif !compatible && !compatibility_fallback(schema, fullname, fingerprint)
        incompatible_schemas << file
        report_incompatibility(schema, fullname, fingerprint)
      end
    end

    # For a schema that is incompatible with the latest registered schema,
    # check if there is a compatibility break defined and check compatibility
    # using the level defined by the break.
    def compatibility_fallback(schema, fullname, fingerprint)
      compatibility_break = compatibility_breaks[[fullname, fingerprint]]

      if compatibility_break
        logger.info("... Checking compatibility with level set to #{compatibility_break.with_compatibility}")
        schema_registry.compatible?(fullname, schema, 'latest', with_compatibility: compatibility_break.with_compatibility)
      else
        false
      end
    end

    def report_incompatibility(schema, fullname, fingerprint)
      last_json = schema_registry.subject_version(fullname)['schema']
      last_schema = Avro::Schema.parse(last_json)
      backward = last_schema.read?(schema)
      forward = schema.read?(last_schema)
      compatibility_with_last = if backward && forward
                                  FULL
                                elsif backward
                                  BACKWARD
                                elsif forward
                                  FORWARD
                                else
                                  NONE
                                end

      logger.info("... Compatibility with last version: #{compatibility_with_last}")
      logger.info(Diffy::Diff.new(last_json, schema.to_s, context: 3).to_s) unless compatibility_with_last == FULL

      compatibility = schema_registry.subject_config(fullname)['compatibility'] || schema_registry.global_config['compatibility']
      logger.info("... Current compatibility level: #{compatibility}")
      logger.info(
        "  To allow a compatibility break, run:\n" \
        "  rake avro:add_compatibility_break name=#{fullname} fingerprint=#{fingerprint} with_compatibility=#{compatibility_with_last} [after_compatibility=<LEVEL>]"
      )
    end

    def roots
      paths = [File.join(Rails.root, 'avro/schema')]
      gem_schemas = File.join(Rails.root, 'schemas_gem/avro/schema')
      paths << gem_schemas if File.exist?(gem_schemas)
      paths
    end

    def build_schema_registry
      registry_url = ENV['COMPATIBILITY_REGISTRY_URL'] || heroku_registry_url
      AvroTurf::ConfluentSchemaRegistry.new(registry_url, logger: Rails.logger)
    end

    def heroku_registry_url
      heroku = PlatformAPI.connect_oauth(heroku_auth_token)
      password = heroku.config_var.info_for_app('schema-registry-prod')['SCHEMA_REGISTRY_PASSWORD']
      "https://compatibility:#{password}@schema-registry.internal.salsify.com"
    end

    def heroku_auth_token
      unless File.exist?(Netrc.default_path)
        raise "Heroku credentials not found in #{Netrc.default_path}. Run heroku auth:login"
      end

      netrc = Netrc.read
      netrc.dig('api.heroku.com', 1)
    end
  end
end
