# frozen_string_literal: true

require "test_helper"

class Oroshi::ShippingMethodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    # Skip onboarding for admin user
    create(:onboarding_progress, :completed, user: @admin)
    sign_in @admin
  end

  # GET #index
  test "GET index returns http success" do
    create(:oroshi_shipping_organization)
    get oroshi.shipping_methods_path
    assert_response :success
  end

  # GET #edit
  test "GET edit returns http success" do
    shipping_method = create(:oroshi_shipping_method)
    get oroshi.edit_shipping_method_path(shipping_method)
    assert_response :success
  end

  # GET #new
  test "GET new returns http success" do
    get oroshi.new_shipping_method_path
    assert_response :success
  end

  # POST #create
  test "POST create returns http success with valid params" do
    create(:oroshi_shipping_organization)
    shipping_method_attributes = attributes_for(:oroshi_shipping_method,
                                                shipping_organization_id: Oroshi::ShippingOrganization.first.id)
    post oroshi.shipping_methods_path, params: { oroshi_shipping_method: shipping_method_attributes }
  end

  test "POST create returns http unprocessable_entity with invalid params" do
    shipping_method_attributes = attributes_for(:oroshi_shipping_method, company_name: nil)
    post oroshi.shipping_methods_path, params: { oroshi_shipping_method: shipping_method_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update returns http success" do
    shipping_method = create(:oroshi_shipping_method)
    updated_attributes = attributes_for(:oroshi_shipping_method, company_name: "Updated Company Name")
    patch oroshi.shipping_method_path(shipping_method), params: { oroshi_shipping_method: updated_attributes }
    assert_response :success
  end
end
