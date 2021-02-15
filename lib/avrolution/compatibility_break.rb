# frozen_string_literal: true

require 'active_model'

module Avrolution
  class CompatibilityBreak
    include ActiveModel::Validations

    ValidationError = Class.new(StandardError)

    VALID_COMPATIBILITY_VALUES = [
      'BACKWARD',
      'BACKWARD_TRANSITIVE',
      'FORWARD',
      'FORWARD_TRANSITIVE',
      'FULL',
      'FULL_TRANSITIVE',
      'NONE'
    ].freeze
    NONE = 'NONE'

    attr_reader :name, :fingerprint, :with_compatibility, :after_compatibility

    validates_presence_of :name, :fingerprint
    validates_inclusion_of :with_compatibility, in: VALID_COMPATIBILITY_VALUES, allow_nil: true
    validates_inclusion_of :after_compatibility, in: VALID_COMPATIBILITY_VALUES, allow_nil: true

    def initialize(name, fingerprint, with_compatibility = NONE, after_compatibility = nil, *extra)
      @name = name
      @fingerprint = fingerprint
      @with_compatibility = with_compatibility.upcase
      @after_compatibility = after_compatibility.try(:upcase)
      @extra = extra
    end

    def key
      [name, fingerprint]
    end

    def validate!
      raise ValidationError.new(errors.full_messages.join(', ')) unless valid?
    end

    def line
      [name, fingerprint, with_compatibility, after_compatibility].compact.join(' ')
    end

    def register_options
      { with_compatibility: with_compatibility }.tap do |options|
        options[:after_compatibility] = after_compatibility if after_compatibility.present?
      end
    end
  end
end
