# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class SupplyTypeTest < ActiveSupport::TestCase
    def setup
      @supply_type = build(:oroshi_supply_type)
    end

    test 'is valid with valid attributes' do
      assert @supply_type.valid?
    end

    # Validations
    test 'is not valid without a name' do
      @supply_type.name = nil
      assert_not @supply_type.valid?
    end

    test 'is not valid without a handle' do
      @supply_type.handle = nil
      assert_not @supply_type.valid?
    end

    test 'is not valid without units' do
      @supply_type.units = nil
      assert_not @supply_type.valid?
    end

    test 'is not valid without liquid' do
      @supply_type.liquid = nil
      assert_not @supply_type.valid?
    end

    test 'is not valid without active' do
      @supply_type.active = nil
      assert_not @supply_type.valid?
    end

    # Association Assignments
    # Tested through variations
  end
end
