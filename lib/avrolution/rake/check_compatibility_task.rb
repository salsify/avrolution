# frozen_string_literal: true

require 'avrolution/rake/base_task'

module Avrolution
  module Rake
    class CheckCompatibilityTask < BaseTask

      def initialize(**)
        super
        @name ||= :check_compatibility
        @task_desc ||= 'Check that all Avro schemas are compatible with latest registered in production'
      end

      private

      def perform
        check = Avrolution::CompatibilityCheck.new.call
        if check.success?
          puts 'All schemas are compatible!'
        else
          puts "\nIncompatible schemas found: #{check.incompatible_schemas.join(', ')}"
          exit(1)
        end
      end
    end
  end
end
