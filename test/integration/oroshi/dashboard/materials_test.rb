# frozen_string_literal: true

require 'test_helper'

module Oroshi
  module Dashboard
    class MaterialsTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:user, :admin)
        sign_in @admin
      end

      test 'renders materials dashboard partial with turbo frames' do
        get oroshi_dashboard_materials_path

        assert_response :success
        # Materials has tabs with different turbo frames: shipping_receptacles, packagings, material_categories
        assert_match(/turbo-frame[^>]*id="shipping_receptacles"/, response.body)
        assert_match(/turbo-frame[^>]*id="packagings"/, response.body)
        assert_match(/turbo-frame[^>]*id="material_categories"/, response.body)
      end

      test 'renders materials dashboard with data' do
        create_list(:oroshi_material_category, 2)
        create_list(:oroshi_material, 5)

        get oroshi_dashboard_materials_path

        assert_response :success
        assert_match(/turbo-frame[^>]*id="shipping_receptacles"/, response.body)
      end
    end
  end
end
