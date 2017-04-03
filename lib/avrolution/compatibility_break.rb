require 'active_model'

module Avrolution
  class CompatibilityBreak
    include ActiveModel::Validations

    ValidationError = Class.new(StandardError)

    VALID_COMPATIBILITY_VALUES = %w(BACKWARD BACKWARD_TRANSITIVE FORWARD
                                    FORWARD_TRANSITIVE FULL FULL_TRANSITIVE NONE).map(&:freeze).freeze
    NONE = 'NONE'.freeze

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
  end
end
