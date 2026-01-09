# frozen_string_literal: true

require "test_helper"

class Oroshi::ProductTest < ActiveSupport::TestCase
  def setup
    @product = build(:oroshi_product)
  end

  test "is valid with valid attributes" do
    assert @product.valid?
  end

  # Validations
  test "is not valid without a name" do
    @product.name = nil
    assert_not @product.valid?
  end

  test "is not valid without units" do
    @product.units = nil
    assert_not @product.valid?
  end

  test "is not valid without active" do
    @product.active = nil
    assert_not @product.valid?
  end
end
