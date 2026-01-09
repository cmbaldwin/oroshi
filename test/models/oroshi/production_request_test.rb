# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class ProductionRequestTest < ActiveSupport::TestCase
    def setup
      @production_request = build(:oroshi_production_request)
    end

    test 'is valid with valid attributes' do
      assert @production_request.valid?
    end

    # Validations
    test 'is not valid without a request_quantity' do
      @production_request.request_quantity = nil
      assert_not @production_request.valid?
    end

    test 'is not valid without a fulfilled_quantity' do
      @production_request.fulfilled_quantity = nil
      assert_not @production_request.valid?
    end

    test 'is not valid without a status' do
      @production_request.status = nil
      assert_not @production_request.valid?
    end

    # Associations
    test 'belongs to a product variation' do
      production_request = create(:oroshi_production_request)
      assert_instance_of Oroshi::ProductVariation, production_request.product_variation
    end

    test 'has many supply type variations through product variation' do
      production_request = create(:oroshi_production_request)
      assert_equal production_request.product_variation.supply_type_variations,
                   production_request.supply_type_variations
    end

    test 'belongs to a product_inventory' do
      production_request = create(:oroshi_production_request)
      assert_instance_of Oroshi::ProductInventory, production_request.product_inventory
      assert_equal production_request.product_variation, production_request.product_inventory.product_variation
    end

    test 'belongs to a production zone' do
      production_request = create(:oroshi_production_request)
      assert_instance_of Oroshi::ProductionZone, production_request.production_zone
    end

    test 'belongs to a shipping receptacle' do
      production_request = create(:oroshi_production_request)
      assert_instance_of Oroshi::ShippingReceptacle, production_request.shipping_receptacle
    end
  end
end
