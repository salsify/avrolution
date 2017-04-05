require 'rails/generators/base'

module Avrolution
  class InstallGenerator < Rails::Generators::Base
    source_paths << File.join(__dir__, 'templates')

    def create_compatibility_breaks_file
      copy_file('avro_compatibility_breaks.txt')
    end
  end
end
