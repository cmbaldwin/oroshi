# frozen_string_literal: true

require "test_helper"

class Oroshi::ShippingReceptacleTest < ActiveSupport::TestCase
  def setup
    @shipping_receptacle = build(:oroshi_shipping_receptacle)
  end

  test "is valid with valid attributes" do
    assert @shipping_receptacle.valid?
  end

  # Validations
  test "is not valid without a name" do
    @shipping_receptacle.name = nil
    assert_not @shipping_receptacle.valid?
  end

  test "is not valid without a handle" do
    @shipping_receptacle.handle = nil
    assert_not @shipping_receptacle.valid?
  end

  test "is not valid without a cost" do
    @shipping_receptacle.cost = nil
    assert_not @shipping_receptacle.valid?
  end

  test "is not valid without a default_freight_bundle_quantity" do
    @shipping_receptacle.default_freight_bundle_quantity = nil
    assert_not @shipping_receptacle.valid?
  end

  test "is not valid without active" do
    @shipping_receptacle.active = nil
    assert_not @shipping_receptacle.valid?
  end

  # Production request associations
  test "has many production_requests" do
    shipping_receptacle = create(:oroshi_shipping_receptacle, :with_production_requests)
    assert_operator shipping_receptacle.production_requests.count, :>, 0
  end

  # Order associations
  test "has many orders" do
    shipping_receptacle = create(:oroshi_shipping_receptacle, :with_orders)
    assert_operator shipping_receptacle.orders.count, :>, 0
  end
end
