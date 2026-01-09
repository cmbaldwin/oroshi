# frozen_string_literal: true

require "test_helper"

class Oroshi::BuyersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # GET #index
  test "GET index returns http success" do
    create(:oroshi_buyer)
    get oroshi_buyers_path
    assert_response :success
  end

  # GET #edit
  test "GET edit returns http success" do
    buyer = create(:oroshi_buyer)
    get edit_oroshi_buyer_path(buyer)
    assert_response :success
  end

  # GET #new
  test "GET new returns http success" do
    get new_oroshi_buyer_path
    assert_response :success
  end

  # POST #create
  test "POST create returns http success with valid params" do
    create(:oroshi_shipping_organization)
    buyer_attributes = attributes_for(:oroshi_buyer,
                                      shipping_methods: [ create(:oroshi_shipping_method) ])
    post oroshi_buyers_path, params: { oroshi_buyer: buyer_attributes }
  end

  test "POST create returns http unprocessable_entity with invalid params" do
    buyer_attributes = attributes_for(:oroshi_buyer, name: nil)
    post oroshi_buyers_path, params: { oroshi_buyer: buyer_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update returns http success" do
    buyer = create(:oroshi_buyer)
    updated_attributes = attributes_for(:oroshi_buyer, name: "Updated Name")
    patch oroshi_buyer_path(buyer), params: { oroshi_buyer: updated_attributes }
    assert_response :success
  end
end
