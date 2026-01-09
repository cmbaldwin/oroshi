# frozen_string_literal: true

class Setting < ApplicationRecord
  # Returns settings hash, handling nil gracefully
  def safe_settings
    settings || {}
  end

  # Returns masked value for sensitive settings
  def masked_setting(key)
    value = safe_settings[key]
    return nil if value.blank?

    # Mask all but last 4 characters
    value.length <= 4 ? '*' * value.length : '*' * (value.length - 4) + value[-4..]
  end
end
