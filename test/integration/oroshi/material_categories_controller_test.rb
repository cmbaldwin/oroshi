# frozen_string_literal: true

require "test_helper"

class Oroshi::MaterialCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    # Skip onboarding for admin user
    create(:onboarding_progress, :completed, user: @admin)
    sign_in @admin
  end

  # GET #index
  test "GET index returns http success" do
    get oroshi.material_categories_path
    assert_response :success
  end

  # GET #edit
  test "GET edit returns http success" do
    material_category = create(:oroshi_material_category)
    get oroshi.edit_material_category_path(material_category)
    assert_response :success
  end

  # GET #new
  test "GET new returns http success" do
    get oroshi.new_material_category_path
    assert_response :success
  end

  # POST #create
  test "POST create returns http success with valid params" do
    material_category_attributes = attributes_for(:oroshi_material_category)
    post oroshi.material_categories_path, params: { oroshi_material_category: material_category_attributes }
  end

  test "POST create returns http unprocessable_entity with invalid params" do
    material_category_attributes = attributes_for(:oroshi_material_category, name: nil)
    post oroshi.material_categories_path, params: { oroshi_material_category: material_category_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update returns http success" do
    material_category = create(:oroshi_material_category)
    updated_attributes = attributes_for(:oroshi_material_category, name: "Updated Name")
    patch oroshi.material_category_path(material_category), params: { oroshi_material_category: updated_attributes }
    assert_response :success
  end
end
