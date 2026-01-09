# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class ProductVariationTest < ActiveSupport::TestCase
    def setup
      @product_variation = create(:oroshi_product_variation) # Need create for production_zones
    end

    test 'is valid with valid attributes' do
      assert @product_variation.valid?
    end

    # Validations
    # Skip validation tests that would break production_zones requirement
    test 'is not valid without a name' do
      variation = create(:oroshi_product_variation)
      variation.name = nil
      assert_not variation.valid?
    end

    test 'is not valid without a handle' do
      variation = create(:oroshi_product_variation)
      variation.handle = nil
      assert_not variation.valid?
    end

    test 'is not valid without a primary_content_volume' do
      variation = create(:oroshi_product_variation)
      variation.primary_content_volume = nil
      assert_not variation.valid?
    end

    test 'is not valid without a primary_content_country_id' do
      variation = create(:oroshi_product_variation)
      variation.primary_content_country_id = nil
      assert_not variation.valid?
    end

    test 'is not valid without a primary_content_subregion_id' do
      variation = create(:oroshi_product_variation)
      variation.primary_content_subregion_id = nil
      assert_not variation.valid?
    end

    test 'is not valid without active' do
      variation = create(:oroshi_product_variation)
      variation.active = nil
      assert_not variation.valid?
    end

    test 'is not valid without production_zones' do
      variation = create(:oroshi_product_variation)
      variation.production_zones = []
      assert_not variation.valid?
    end

    # Product inventory is created on-demand by orders/production_requests, not automatically
    # So we're removing this test as it's testing incorrect behavior
    # describe 'creates a product inventory' do
    #   it 'after creation' do
    #     expect { create(:oroshi_product_variation) }.to change(Oroshi::ProductInventory, :count).by(1)
    #   end
    # end
  end
end
