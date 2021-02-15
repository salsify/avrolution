# frozen_string_literal: true

require 'avrolution/rake/base_task'

module Avrolution
  module Rake
    class RegisterSchemasTask < BaseTask

      def initialize(*)
        super
        @name ||= :register_schemas
        @task_desc ||= 'Register the specified Avro JSON schemas'
      end

      private

      def perform
        raise 'schemas must be specified' if ENV['schemas'].blank?

        schemas = ENV['schemas'].split(',')

        Avrolution::RegisterSchemas.call(schemas)
      end
    end
  end
end
