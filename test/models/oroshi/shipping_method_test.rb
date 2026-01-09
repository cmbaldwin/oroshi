# frozen_string_literal: true

require "test_helper"

class Oroshi::ShippingMethodTest < ActiveSupport::TestCase
  def setup
    @shipping_method = build(:oroshi_shipping_method)
  end

  test "is valid with valid attributes" do
    assert @shipping_method.valid?
  end

  # Validations
  test "is not valid without a name" do
    @shipping_method.name = nil
    assert_not @shipping_method.valid?
  end

  test "is not valid without a handle" do
    @shipping_method.handle = nil
    assert_not @shipping_method.valid?
  end

  # Associations
  test "has many buyers" do
    buyers = create_list(:oroshi_buyer, rand(1..3))
    shipping_method = create(:oroshi_shipping_method, buyers: buyers)
    assert_operator shipping_method.buyers.length, :>, 0
  end
end
