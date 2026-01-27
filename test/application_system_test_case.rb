# frozen_string_literal: true

require "test_helper"
require "capybara/rails"
require "capybara/minitest"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  # Enable Warden test mode
  Warden.test_mode!

  # Default to rack_test (fast, no JS)
  driven_by :rack_test

  # Configure Capybara
  Capybara.default_max_wait_time = 3
  Capybara.server = :puma, { Silent: true }

  # Clean up Warden after each test
  teardown do
    Warden.test_reset!
  end

  include OroshiRouteHelpers
end

# Helper module for JS tests
module JavaScriptTest
  def self.included(base)
    base.class_eval do
      driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")
      end
    end
  end
end
