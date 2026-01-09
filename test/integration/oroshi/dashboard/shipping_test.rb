# frozen_string_literal: true

require "test_helper"

module Oroshi
  module Dashboard
    class ShippingTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:user, :admin)
        sign_in @admin
      end

      test "renders shipping dashboard partial with turbo frames" do
        get oroshi_dashboard_shipping_path

        assert_response :success
        assert_match(/turbo-frame[^>]*id="shipping_organizations"/, response.body)
        assert_match(/turbo-frame[^>]*id="shipping_organizations_shipping_settings"/, response.body)
      end

      test "renders shipping dashboard with data" do
        create_list(:oroshi_shipping_organization, 2)
        create_list(:oroshi_shipping_method, 3)

        get oroshi_dashboard_shipping_path

        assert_response :success
        assert_match(/turbo-frame[^>]*id="shipping_organizations"/, response.body)
      end
    end
  end
end
