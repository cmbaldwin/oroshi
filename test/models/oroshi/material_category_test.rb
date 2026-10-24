# frozen_string_literal: true

require "test_helper"

class Oroshi::MaterialCategoryTest < ActiveSupport::TestCase
  def setup
    @material_category = build(:oroshi_material_category)
  end

  # --- Validity ---

  test "is valid with valid attributes" do
    assert @material_category.valid?
  end

  # --- Validations ---

  test "is not valid without a name" do
    @material_category.name = nil
    assert_not @material_category.valid?
    assert_includes @material_category.errors[:name], I18n.t("errors.messages.blank")
  end

  test "is not valid when active is nil (Activatable concern)" do
    @material_category.active = nil
    assert_not @material_category.valid?
  end

  test "is valid when active is false" do
    @material_category.active = false
    assert @material_category.valid?
  end

  # --- Activatable scopes ---

  test "active scope returns only active categories" do
    active_cat = create(:oroshi_material_category, active: true)
    inactive_cat = create(:oroshi_material_category, active: false)

    assert_includes Oroshi::MaterialCategory.active, active_cat
    assert_not_includes Oroshi::MaterialCategory.active, inactive_cat
  end

  test "inactive scope returns only inactive categories" do
    active_cat = create(:oroshi_material_category, active: true)
    inactive_cat = create(:oroshi_material_category, active: false)

    assert_includes Oroshi::MaterialCategory.inactive, inactive_cat
    assert_not_includes Oroshi::MaterialCategory.inactive, active_cat
  end

  # --- Associations ---

  test "has many materials" do
    assert_respond_to @material_category, :materials
  end

  test "materials are destroyed when category is destroyed" do
    category = create(:oroshi_material_category)
    material = create(:oroshi_material, material_category: category)
    assert_equal 1, category.materials.count

    assert_difference "Oroshi::Material.count", -1 do
      category.destroy
    end
  end
end
