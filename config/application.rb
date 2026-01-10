# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Dev evniornment ENV file
if defined?(Dotenv)
  require "dotenv-rails"
  Dotenv::Rails.load
end

module Oroshi
  class Application < Rails::Application
  # Initialize configuration defaults for originally generated Rails version.
  config.load_defaults 8.0

  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration can go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded after loading
  # the framework and any gems in your application.

  config.i18n.default_locale = :ja
  config.i18n.available_locales = %i[ja]
  config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]
  config.time_zone = "Osaka"
  config.beginning_of_week = :sunday

  # Explicitly add lib and printables directories
  config.autoload_paths << Rails.root.join("lib")
  config.eager_load_paths << Rails.root.join("lib")
  config.autoload_paths << Rails.root.join("lib", "printables")
  config.eager_load_paths << Rails.root.join("lib", "printables")

    # NOTE: Solid Cache and Solid Cable database connections are configured
    # in config/environments/production.rb to ensure gems are loaded first
  end
end
