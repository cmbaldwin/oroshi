# frozen_string_literal: true

require 'test_helper'

module Oroshi
  module Dashboard
    class ProductsTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:user, :admin)
        sign_in @admin
      end

      test 'renders products dashboard partial with turbo frames' do
        get oroshi_dashboard_products_path

        assert_response :success
        assert_match(/turbo-frame[^>]*id="products"/, response.body)
        assert_match(/turbo-frame[^>]*id="product_settings"/, response.body)
      end

      test 'renders products dashboard with data' do
        create_list(:oroshi_product, 3)
        create_list(:oroshi_product_variation, 5)

        get oroshi_dashboard_products_path

        assert_response :success
        assert_match(/turbo-frame[^>]*id="products"/, response.body)
      end
    end
  end
end
