# frozen_string_literal: true

require "test_helper"

class EngineMountingTest < ActionDispatch::IntegrationTest
  test "engine routes are mounted" do
    # The engine should be mounted at /oroshi
    assert_recognizes(
      { controller: "oroshi/dashboard", action: "index" },
      "/oroshi"
    )
  end

  test "health check route works" do
    get "/up"
    assert_response :success
  end

  test "engine is loaded" do
    assert defined?(Oroshi::Engine)
    assert Oroshi::Engine < Rails::Engine
  end
end
