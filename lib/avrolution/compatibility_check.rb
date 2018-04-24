require 'avro-resolution_canonical_form'
require 'private_attr'
require 'diffy'
require 'avro_schema_registry-client'

module Avrolution
  class CompatibilityCheck
    extend PrivateAttr

    attr_reader :incompatible_schemas

    NONE = 'NONE'.freeze
    FULL = 'FULL'.freeze
    BOTH = 'BOTH'.freeze
    BACKWARD = 'BACKWARD'.freeze
    FORWARD = 'FORWARD'.freeze

    private_attr_reader :schema_registry, :compatibility_breaks,
                        :logger

    def initialize(logger: Avrolution.logger)
      @incompatible_schemas = []
      @schema_registry = build_schema_registry
      @compatibility_breaks = Avrolution::CompatibilityBreaksFile.load
      @logger = logger
    end

    def call
      check_schemas(Avrolution.root)
      self
    end

    def success?
      incompatible_schemas.empty?
    end

    private

    def check_schemas(path)
      vendor_bundle_path = File.join(path, 'vendor/bundle/')
      Dir[File.join(path, '**/*.avsc')].reject do |file|
        file.start_with?(vendor_bundle_path)
      end.each do |schema_file|
        check_schema_compatibility(schema_file)
      end
    end

    def check_schema_compatibility(file)
      json = File.read(file)
      schema = Avro::Schema.parse(json)
      return unless schema.type_sym == :record

      fullname = schema.fullname
      fingerprint = schema.sha256_resolution_fingerprint.to_s(16)

      logger.info("Checking compatibility: #{fullname}")
      return if schema_registered?(fullname, schema)
      compatible = schema_registry.compatible?(fullname, schema, 'latest')

      if compatible.nil?
        # compatible is nil if the subject is not registered
        logger.info("... New schema: #{fullname}")
      elsif !compatible && !compatibility_fallback(schema, fullname, fingerprint)
        incompatible_schemas << file
        report_incompatibility(json, schema, fullname, fingerprint)
      end
    end

    def schema_registered?(fullname, schema)
      schema_registry.lookup_subject_schema(fullname, schema)
    rescue Excon::Errors::NotFound
      nil
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

    def report_incompatibility(json, schema, fullname, fingerprint)
      last_json = schema_registry.subject_version(fullname)['schema']
      last_schema = Avro::Schema.parse(last_json)
      backward = schema.read?(last_schema)
      forward = last_schema.read?(schema)
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
      logger.info(Diffy::Diff.new(last_json, json, context: 3).to_s) unless compatibility_with_last == FULL

      compatibility = schema_registry.subject_config(fullname)['compatibility'] || schema_registry.global_config['compatibility']
      compatibility = FULL if compatibility == BOTH
      logger.info("... Current compatibility level: #{compatibility}")
      logger.info(
        "\n  To allow a compatibility break, run:\n" \
        "    rake avro:add_compatibility_break name=#{fullname} fingerprint=#{fingerprint} with_compatibility=#{compatibility_with_last} [after_compatibility=<LEVEL>]\n"
      )
    end

    def build_schema_registry
      AvroSchemaRegistry::Client.new(Avrolution.compatibility_schema_registry_url,
                                     logger: Avrolution.logger)
    end
  end
end
