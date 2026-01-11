# frozen_string_literal: true

# Oroshi Engine Configuration
Oroshi.configure do |config|
  # Application timezone (Japanese time zone by default)
  config.time_zone = "Asia/Tokyo"

  # Default locale (Japanese by default)
  config.locale = :ja

  # Application domain (for URL generation)
  # In production, set via OROSHI_DOMAIN environment variable
  config.domain = ENV.fetch("OROSHI_DOMAIN", "localhost")
end

# Ensure Rails uses the configured timezone
Rails.application.config.time_zone = Oroshi.configuration.time_zone
Rails.application.config.active_record.default_timezone = :utc

# Ensure Rails uses the configured locale
Rails.application.config.i18n.default_locale = Oroshi.configuration.locale
Rails.application.config.i18n.available_locales = [:ja, :en]
