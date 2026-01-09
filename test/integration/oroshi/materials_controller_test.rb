# frozen_string_literal: true

require "test_helper"

class Oroshi::MaterialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # GET #index
  test "GET index returns http success" do
    material_category = create(:oroshi_material_category)
    get oroshi_materials_path, params: { material_category_id: material_category.id }
    assert_response :success
  end

  test "GET index renders the index template" do
    material_category = create(:oroshi_material_category)
    get oroshi_materials_path, params: { material_category_id: material_category.id }
    assert_response :success
  end

  # GET #edit
  test "GET edit returns http success" do
    material = create(:oroshi_material)
    get edit_oroshi_material_path(material)
    assert_response :success
  end

  # GET #new
  test "GET new returns http success" do
    get new_oroshi_material_path
    assert_response :success
  end

  # POST #create
  test "POST create returns http success with valid params" do
    material_category = create(:oroshi_material_category)
    material_attributes = attributes_for(:oroshi_material,
                                         material_category_id: material_category.id)
    post oroshi_materials_path, params: { oroshi_material: material_attributes }
  end

  test "POST create returns http unprocessable_entity with invalid params" do
    material_attributes = attributes_for(:oroshi_material, company_name: nil)
    post oroshi_materials_path, params: { oroshi_material: material_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update returns http success" do
    material = create(:oroshi_material)
    updated_attributes = attributes_for(:oroshi_material, company_name: "Updated Name")
    patch oroshi_material_path(material), params: { oroshi_material: updated_attributes }
    assert_response :success
  end
end
