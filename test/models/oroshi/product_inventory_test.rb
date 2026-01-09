# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class ProductInventoryTest < ActiveSupport::TestCase
    def setup
      @product_inventory = build(:oroshi_product_inventory)
    end

    test 'is valid with valid attributes' do
      assert @product_inventory.valid?
    end

    # Validations
    test 'is not valid without a quantity' do
      @product_inventory.quantity = nil
      assert_not @product_inventory.valid?
    end

    # Is updated by product requests and orders
    test 'updates the product inventory quantity after production request update' do
      product_variation = create(:oroshi_product_variation)
      product_inventory = create(:oroshi_product_inventory, product_variation: product_variation, quantity: 0)
      production_request = create(:oroshi_production_request,
                                  fulfilled_quantity: 0,
                                  product_variation: product_variation,
                                  product_inventory: product_inventory)

      # Test production requests increase inventory
      production_request.update(status: :completed, fulfilled_quantity: 5)
      assert_equal 5, product_inventory.reload.quantity

      production_request.update(status: :completed, fulfilled_quantity: 10)
      assert_equal 10, product_inventory.reload.quantity

      # Test orders decrease inventory when shipped
      buyer = create(:oroshi_buyer)
      shipping_method = buyer.shipping_methods.first
      order = create(:oroshi_order,
                     product_variation: product_variation,
                     product_inventory: product_inventory,
                     status: :confirmed,
                     shipping_method: shipping_method,
                     item_quantity: 5,
                     buyer: buyer)
      order.update(status: :shipped)
      assert_equal 5, product_inventory.reload.quantity # 10 - 5
    end
  end
end
