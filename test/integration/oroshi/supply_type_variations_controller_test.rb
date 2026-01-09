# frozen_string_literal: true

require "test_helper"

class Oroshi::SupplyTypeVariationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
    create(:oroshi_supply_type)
  end

  # GET #index
  test "GET index returns a success response" do
    get oroshi_supply_type_variations_path
    assert_response :success
  end

  # GET #new
  test "GET new returns a success response" do
    get new_oroshi_supply_type_variation_path
    assert_response :success
  end

  # POST #create
  test "POST create returns http success with valid params" do
    supply_type_variation_attributes = attributes_for(:oroshi_supply_type_variation)
    post oroshi_supply_type_variations_path, params: { oroshi_supply_type_variation: supply_type_variation_attributes }
  end

  test "POST create returns http unprocessable_entity with invalid params" do
    supply_type_variation_attributes = attributes_for(:oroshi_supply_type_variation, name: nil)
    post oroshi_supply_type_variations_path, params: { oroshi_supply_type_variation: supply_type_variation_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update returns http success" do
    supply_type_variation = create(:oroshi_supply_type_variation)
    updated_attributes = attributes_for(:oroshi_supply_type_variation, name: "Updated Supply Type Variation Name")
    patch oroshi_supply_type_variation_path(supply_type_variation), params: { oroshi_supply_type_variation: updated_attributes }
    assert_response :success
  end
end
