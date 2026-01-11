# frozen_string_literal: true

if defined?(Resend)
  Resend.api_key = ENV.fetch("RESEND_API_KEY", nil)
end
