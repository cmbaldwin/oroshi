require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)
require "oroshi"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Asia/Tokyo"
    config.i18n.default_locale = :ja
    config.eager_load = false

    # Configure Oroshi
    Oroshi.configure do |oroshi|
      oroshi.time_zone = "Asia/Tokyo"
      oroshi.locale = :ja
      oroshi.domain = "localhost:3000"
    end
  end
end
