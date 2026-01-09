# frozen_string_literal: true

require "test_helper"

module Oroshi
  module Dashboard
    class BuyersTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:user, :admin)
        sign_in @admin
      end

      test "renders buyers dashboard partial with turbo frames when empty" do
        get oroshi_dashboard_buyers_path

        assert_response :success
        # Check for lazy-loading turbo frames
        assert_match(/turbo-frame[^>]*id="buyers"/, response.body)
        assert_match(/turbo-frame[^>]*id="buyer"/, response.body)
      end

      test "renders buyers dashboard partial with existing buyers" do
        create_list(:oroshi_buyer, 3)

        get oroshi_dashboard_buyers_path

        assert_response :success
        # Check for lazy-loading turbo frames
        assert_match(/turbo-frame[^>]*id="buyers"/, response.body)
        assert_match(/turbo-frame[^>]*id="buyer"/, response.body)
      end
    end
  end
end
