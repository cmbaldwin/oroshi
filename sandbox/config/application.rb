require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OroshiSandbox
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Oroshi configuration
    Oroshi.configure do |oroshi|
      oroshi.time_zone = "Asia/Tokyo"
      oroshi.locale = :ja
      oroshi.domain = ENV.fetch("OROSHI_DOMAIN", "localhost")
    end

    # Application timezone
    config.time_zone = "Asia/Tokyo"
    config.active_record.default_timezone = :utc

    # Locale
    config.i18n.default_locale = :ja
    config.i18n.available_locales = [:ja, :en]

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
