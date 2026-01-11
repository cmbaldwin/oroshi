# frozen_string_literal: true

require "test_helper"

class OroshiTest < ActiveSupport::TestCase
  test "has a version number" do
    assert_not_nil Oroshi::VERSION
  end

  test "can configure with block" do
    Oroshi.reset_configuration!

    Oroshi.configure do |config|
      config.time_zone = "Tokyo"
      config.locale = :en
      config.domain = "example.com"
    end

    assert_equal "Tokyo", Oroshi.configuration.time_zone
    assert_equal :en, Oroshi.configuration.locale
    assert_equal "example.com", Oroshi.configuration.domain

    # Reset to defaults
    Oroshi.reset_configuration!
  end

  test "configuration has sensible defaults" do
    config = Oroshi::Configuration.new

    assert_equal "Asia/Tokyo", config.time_zone
    assert_equal :ja, config.locale
    assert_equal "localhost", config.domain
  end
end
