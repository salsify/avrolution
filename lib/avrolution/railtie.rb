# frozen_string_literal: true

module Avrolution
  class Railtie < Rails::Railtie

    initializer 'avrolution.configure' do
      Avrolution.configure do |config|
        config.root = Rails.root
      end
    end

    rake_tasks do
      load File.expand_path('rake/rails_avrolution.rake', __dir__)
    end
  end
end
