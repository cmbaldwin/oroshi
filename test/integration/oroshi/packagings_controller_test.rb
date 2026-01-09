# frozen_string_literal: true

require "test_helper"

class Oroshi::PackagingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # GET #index
  test "GET index returns http success" do
    get oroshi_packagings_path
    assert_response :success
  end

  # GET #edit
  test "GET edit returns http success" do
    packaging = create(:oroshi_packaging)
    get edit_oroshi_packaging_path(packaging)
    assert_response :success
  end

  # GET #new
  test "GET new returns http success" do
    get new_oroshi_packaging_path
    assert_response :success
  end

  # POST #create
  test "POST create returns http success with valid params" do
    packaging_attributes = attributes_for(:oroshi_packaging)
    post oroshi_packagings_path, params: { oroshi_packaging: packaging_attributes }
  end

  test "POST create returns http unprocessable_entity with invalid params" do
    packaging_attributes = attributes_for(:oroshi_packaging, name: nil)
    post oroshi_packagings_path, params: { oroshi_packaging: packaging_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update returns http success" do
    packaging = create(:oroshi_packaging)
    updated_attributes = attributes_for(:oroshi_packaging, name: "Updated Name")
    patch oroshi_packaging_path(packaging), params: { oroshi_packaging: updated_attributes }
    assert_response :success
  end
end
