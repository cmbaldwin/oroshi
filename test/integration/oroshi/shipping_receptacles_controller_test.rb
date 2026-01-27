# frozen_string_literal: true

require "test_helper"

class Oroshi::ShippingReceptaclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    # Skip onboarding for admin user
    create(:onboarding_progress, :completed, user: @admin)
    sign_in @admin
  end

  # GET #index
  test "GET index returns http success" do
    get oroshi.shipping_receptacles_path
    assert_response :success
  end

  # GET #edit
  test "GET edit returns http success" do
    shipping_receptacle = create(:oroshi_shipping_receptacle)
    get oroshi.edit_shipping_receptacle_path(shipping_receptacle)
    assert_response :success
  end

  # GET #new
  test "GET new returns http success" do
    get oroshi.new_shipping_receptacle_path
    assert_response :success
  end

  # POST #create
  test "POST create returns http success with valid params" do
    shipping_receptacle_attributes = attributes_for(:oroshi_shipping_receptacle)
    post oroshi.shipping_receptacles_path, params: { oroshi_shipping_receptacle: shipping_receptacle_attributes }
  end

  test "POST create returns http unprocessable_entity with invalid params" do
    shipping_receptacle_attributes = attributes_for(:oroshi_shipping_receptacle, name: nil)
    post oroshi.shipping_receptacles_path, params: { oroshi_shipping_receptacle: shipping_receptacle_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update returns http success" do
    shipping_receptacle = create(:oroshi_shipping_receptacle)
    updated_attributes = attributes_for(:oroshi_shipping_receptacle, name: "Updated Name")
    patch oroshi.shipping_receptacle_path(shipping_receptacle), params: { oroshi_shipping_receptacle: updated_attributes }
    assert_response :success
  end
end
