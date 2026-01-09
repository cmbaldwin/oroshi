# frozen_string_literal: true

require "test_helper"

class Oroshi::ProductVariationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
    create(:oroshi_product)
  end

  # GET #index
  test "GET index returns a success response" do
    get oroshi_product_variations_path
    assert_response :success
  end

  # GET #new
  test "GET new returns a success response" do
    get new_oroshi_product_variation_path
    assert_response :success
  end

  # POST #create
  test "POST create returns http success with valid params" do
    product_variation_attributes = attributes_for(:oroshi_product_variation)
    post oroshi_product_variations_path, params: { oroshi_product_variation: product_variation_attributes }
  end

  test "POST create returns http unprocessable_entity with invalid params" do
    product_variation_attributes = attributes_for(:oroshi_product_variation, name: nil)
    post oroshi_product_variations_path, params: { oroshi_product_variation: product_variation_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update returns http success" do
    product_variation = create(:oroshi_product_variation)
    updated_attributes = attributes_for(:oroshi_product_variation, name: "Updated Product Variation Name")
    patch oroshi_product_variation_path(product_variation), params: { oroshi_product_variation: updated_attributes }
    assert_response :success
  end
end
