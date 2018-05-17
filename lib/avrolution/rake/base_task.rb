require 'rake/tasklib'

module Avrolution
  module Rake
    class BaseTask < ::Rake::TaskLib

      attr_accessor :name, :task_namespace, :task_desc, :dependencies

      def self.define(**options, &block)
        new(**options, &block).define
      end

      def initialize(name: nil, dependencies: [])
        @name = name
        @task_namespace = :avro
        @dependencies = dependencies

        yield self if block_given?
      end

      def define
        namespace task_namespace do
          desc task_desc
          task(name.to_sym => dependencies) do
            perform
          end
        end
      end

      private

      def perform
        raise NotImplementedError
      end
    end
  end
end
