# frozen_string_literal: true

require "test_helper"

class Oroshi::TemplatesRouteTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, confirmed_at: Time.current, approved: true, role: :admin)
    @user.create_onboarding_progress!(completed_at: Time.current)
    sign_in @user
  end

  test "templates route loads successfully with no templates" do
    # Ensure no templates exist
    Oroshi::OrderTemplate.destroy_all

    get oroshi_orders_templates_path(date: "2026-01-10")

    assert_response :success
    assert_select ".alert-warning", text: /登録されていません|まだ|no.*orders/i
  end

  test "templates route loads successfully with templates" do
    # Create a template
    product = create(:oroshi_product)
    product_variation = create(:oroshi_product_variation, product: product)
    buyer = create(:oroshi_buyer)
    order = create(:oroshi_order,
                   buyer: buyer,
                   product_variation: product_variation,
                   is_order_template: true)
    template = create(:oroshi_order_template, order: order)

    get oroshi_orders_templates_path(date: "2026-01-10")

    assert_response :success
    assert_no_selector ".alert-warning"
    assert_selector ".order-grid"
  end

  test "templates route with filters and no results" do
    # Create a template
    product = create(:oroshi_product)
    product_variation = create(:oroshi_product_variation, product: product)
    buyer = create(:oroshi_buyer)
    order = create(:oroshi_order,
                   buyer: buyer,
                   product_variation: product_variation,
                   is_order_template: true)
    template = create(:oroshi_order_template, order: order)

    # Filter by non-existent buyer
    get oroshi_orders_templates_path(date: "2026-01-10"), params: { buyer_ids: [99999] }

    assert_response :success
    # Should show no orders warning when filter results are empty
    assert_selector ".alert-warning"
  end
end
