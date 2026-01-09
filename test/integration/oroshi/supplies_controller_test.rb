# frozen_string_literal: true

require "test_helper"

class Oroshi::SuppliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # GET #index
  test "GET index returns http success" do
    get oroshi_supplies_path
    assert_response :success
  end

  # PATCH #update
  test "PATCH update returns http success" do
    supply = create(:oroshi_supply)
    updated_attributes = attributes_for(:oroshi_supply, quantity: 10)
    patch oroshi_supply_path(supply), params: { oroshi_supply: updated_attributes }
    assert_response :success
  end
end
