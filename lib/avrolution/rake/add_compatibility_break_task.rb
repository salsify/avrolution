require 'avrolution/rake/base_task'

module Avrolution
  module Rake
    class AddCompatibilityBreakTask < BaseTask

      def initialize(*)
        super
        @name ||= :add_compatibility_break
        @task_desc ||= 'Add an Avro schema compatibility break. Parameters: name, fingerprint, with_compatibility, after_compatibility'
      end

      private

      def perform
        compatibility_break_args = ENV.to_h.slice('name', 'fingerprint', 'with_compatibility', 'after_compatibility').symbolize_keys

        missing_args = %i(name fingerprint).select do |arg|
          compatibility_break_args[arg].blank?
        end

        if missing_args.any?
          puts missing_args.map { |arg| "#{arg} can't be blank" }.join(', ')
          puts 'Usage: rake avro:add_compatibility_break name=<name> fingerprint=<fingerprint> [with_compatibility=<default:NONE>] [after_compatibility=<compatibility>]'
          exit(1)
        end

        Avrolution::CompatibilityBreaksFile.add(**compatibility_break_args)
      end
    end
  end
end
