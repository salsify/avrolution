# frozen_string_literal: true

module Avrolution
  class DiscoverSchemas
    def self.discover(path)
      vendor_bundle_path = File.join(path, 'vendor/bundle/')
      Dir[File.join(path, '**/*.avsc')].reject do |file|
        file.start_with?(vendor_bundle_path)
      end
    end
  end
end
