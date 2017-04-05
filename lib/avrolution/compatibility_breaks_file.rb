module Avrolution
  module CompatibilityBreaksFile

    NONE = 'NONE'.freeze

    class DuplicateEntryError < StandardError
      def initialize(key)
        super("duplicate entry for key #{key}")
      end
    end

    def self.path
      Avrolution.compatibility_breaks_file
    end

    def self.add(name:,
                 fingerprint:,
                 with_compatibility: NONE,
                 after_compatibility: nil,
                 logger: Avrolution.logger)

      compatibility_break = Avrolution::CompatibilityBreak.new(name, fingerprint, with_compatibility, after_compatibility)
      compatibility_break.validate!

      compatibility_breaks = load
      raise DuplicateEntryError.new([name, fingerprint]) if compatibility_breaks.key?(compatibility_break.key)

      line = compatibility_break.line
      File.write(path, "#{line}\n", mode: 'a')
      logger.info("Added #{line.inspect} to #{path}")
    end

    def self.load
      return {} unless File.exist?(path)

      File.read(path).each_line.each_with_object({}) do |line, compatibility_breaks|
        next if line.blank? || /^#/ =~ line.strip

        compatibility_break = Avrolution::CompatibilityBreak.new(*line.strip.split(' '))
        compatibility_break.validate!

        raise DuplicateEntryError.new(compatibility_break.key) if compatibility_breaks.key?(compatibility_break.key)

        compatibility_breaks[compatibility_break.key] = compatibility_break
      end
    end
  end
end
