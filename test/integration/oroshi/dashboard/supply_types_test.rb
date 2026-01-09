# frozen_string_literal: true

require 'test_helper'

module Oroshi
  module Dashboard
    class SupplyTypesTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:user, :admin)
        sign_in @admin
      end

      test 'renders supply_types dashboard partial with turbo frames' do
        get oroshi_dashboard_supply_types_path

        assert_response :success
        assert_match(/turbo-frame[^>]*id="supply_types"/, response.body)
        assert_match(/turbo-frame[^>]*id="supply_type_settings"/, response.body)
      end

      test 'renders supply types dashboard with data' do
        create_list(:oroshi_supply_type, 3)
        create_list(:oroshi_supply_type_variation, 5)

        get oroshi_dashboard_supply_types_path

        assert_response :success
        assert_match(/turbo-frame[^>]*id="supply_types"/, response.body)
      end
    end
  end
end
