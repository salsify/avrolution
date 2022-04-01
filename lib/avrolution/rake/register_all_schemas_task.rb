# frozen_string_literal: true

require 'avrolution/rake/base_task'

module Avrolution
  module Rake
    class RegisterAllSchemasTask < BaseTask

      def initialize(**)
        super
        @name ||= :register_all_schemas
        @task_desc ||= 'Register all discovered Avro JSON schemas (using Avrolution.root)'
      end

      private

      def perform
        schemas = Avrolution::DiscoverSchemas.discover(Avrolution.root)

        if schemas.blank?
          puts 'could not find any schemas'
        else
          Avrolution::RegisterSchemas.call(schemas)
        end
      end
    end
  end
end
