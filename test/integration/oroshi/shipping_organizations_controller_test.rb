# frozen_string_literal: true

require "test_helper"

class Oroshi::ShippingOrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # GET #index
  test "GET index returns http success" do
    get oroshi_shipping_organizations_path
    assert_response :success
  end

  # GET #load
  test "GET load returns http success" do
    get load_oroshi_shipping_organizations_path
    assert_response :success
  end

  # GET #new
  test "GET new returns http success" do
    get new_oroshi_shipping_organization_path
    assert_response :success
  end

  # POST #create
  test "POST create returns http success with valid params" do
    shipping_organization_attributes = attributes_for(:oroshi_shipping_organization)
    post oroshi_shipping_organizations_path, params: { oroshi_shipping_organization: shipping_organization_attributes }
    assert_response :success
  end

  test "POST create returns http unprocessable_entity with invalid params" do
    shipping_organization_attributes = attributes_for(:oroshi_shipping_organization, name: nil)
    post oroshi_shipping_organizations_path, params: { oroshi_shipping_organization: shipping_organization_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update returns http success" do
    shipping_organization = create(:oroshi_shipping_organization)
    updated_attributes = attributes_for(:oroshi_shipping_organization, name: "Updated Name")
    patch oroshi_shipping_organization_path(shipping_organization), params: { oroshi_shipping_organization: updated_attributes }
    assert_response :success
  end
end
