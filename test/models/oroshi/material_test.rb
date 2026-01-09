# frozen_string_literal: true

require "test_helper"

class Oroshi::MaterialTest < ActiveSupport::TestCase
  def setup
    @material = build(:oroshi_material)
  end

  test "is valid with valid attributes" do
    assert @material.valid?
  end

  # Validations
  test "is not valid without a name" do
    @material.name = nil
    assert_not @material.valid?
  end

  test "is not valid without a cost" do
    @material.cost = nil
    assert_not @material.valid?
  end

  test "is not valid without per" do
    @material.per = nil
    assert_not @material.valid?
  end

  test "is not valid without active" do
    @material.active = nil
    assert_not @material.valid?
  end
end
