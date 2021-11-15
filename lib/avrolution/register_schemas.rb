# frozen_string_literal: true

require 'avro_schema_registry-client'
require 'private_attr'
require 'procto'

module Avrolution
  class RegisterSchemas
    extend PrivateAttr
    include Procto.call

    attr_reader :schema_files

    private_attr_reader :compatibility_breaks, :schema_registry

    class IncompatibleSchemaError < StandardError
      def initialize(name)
        super("incompatible schema #{name}")
      end
    end

    def initialize(schema_files)
      @schema_files = Array(schema_files)
      @compatibility_breaks = Avrolution::CompatibilityBreaksFile.load
      @schema_registry = build_schema_registry
    end

    def call
      schemas.each do |(json, schema)|
        register_schema(schema, json)
      end
    end

    private

    def register_schema(schema, json)
      fullname = schema.fullname
      fingerprint = schema.sha256_resolution_fingerprint.to_s(16)

      compatibility_break = compatibility_breaks[[fullname, fingerprint]]

      begin
        if (opts = compatibility_break.try(:register_options))
          schema_registry.register_without_lookup(
            fullname,
            json,
            **opts
          )
        else
          schema_registry.register_without_lookup(fullname, json)
        end
      rescue Excon::Error::Conflict
        raise IncompatibleSchemaError.new(fullname)
      end
    end

    def schemas
      @schemas ||= schema_files.map do |schema_file|
        if File.exist?(schema_file)
          json = File.read(schema_file)
          [json, Avro::Schema.parse(json)]
        end
      end.compact
    end

    def build_schema_registry
      AvroSchemaRegistry::Client.new(Avrolution.deployment_schema_registry_url,
                                     logger: Avrolution.logger)
    end
  end
end
