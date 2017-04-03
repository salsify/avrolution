module Avrolution
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../rake/avro.rake', __FILE__)
    end
  end
end
