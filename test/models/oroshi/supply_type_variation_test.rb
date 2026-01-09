# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class SupplyTypeVariationTest < ActiveSupport::TestCase
    def setup
      @supply_type_variation = build(:oroshi_supply_type_variation)
    end

    test 'is valid with valid attributes' do
      assert @supply_type_variation.valid?
    end

    # Validations
    test 'is not valid without a supply_type_id' do
      @supply_type_variation.supply_type_id = nil
      assert_not @supply_type_variation.valid?
    end

    test 'is not valid without a name' do
      @supply_type_variation.name = nil
      assert_not @supply_type_variation.valid?
    end

    test 'is not valid without a default_container_count' do
      @supply_type_variation.default_container_count = nil
      assert_not @supply_type_variation.valid?
    end

    test 'is not valid without active' do
      @supply_type_variation.active = nil
      assert_not @supply_type_variation.valid?
    end

    # Association Assignments
    test 'has supply_type' do
      supply_type_variation = create(:oroshi_supply_type_variation)
      assert_instance_of Oroshi::SupplyType, supply_type_variation.supply_type
    end
  end
end
