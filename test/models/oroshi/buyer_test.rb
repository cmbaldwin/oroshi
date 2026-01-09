# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class BuyerTest < ActiveSupport::TestCase
    def setup
      @buyer = build(:oroshi_buyer)
    end

    test 'is valid with valid attributes' do
      assert @buyer.valid?
    end

    test 'is not valid without a name' do
      @buyer.name = nil
      assert_not @buyer.valid?
    end

    test 'is not valid without a handle' do
      @buyer.handle = nil
      assert_not @buyer.valid?
    end

    test 'is not valid without a handling_cost' do
      @buyer.handling_cost = nil
      assert_not @buyer.valid?
    end

    test 'is not valid without a daily_cost' do
      @buyer.daily_cost = nil
      assert_not @buyer.valid?
    end

    test 'is not valid without an entity_type' do
      @buyer.entity_type = nil
      assert_not @buyer.valid?
    end

    test 'is not valid without an optional_cost' do
      @buyer.optional_cost = nil
      assert_not @buyer.valid?
    end

    test 'is not valid without a commission_percentage' do
      @buyer.commission_percentage = nil
      assert_not @buyer.valid?
    end

    test 'is not valid without a valid color' do
      @buyer.color = 'invalid'
      assert_not @buyer.valid?
    end

    test 'has many addresses' do
      buyer = create(:oroshi_buyer, :with_orders)
      assert_operator buyer.addresses.length, :>, 0
    end

    test 'has many shipping methods' do
      buyer = create(:oroshi_buyer, :with_orders)
      assert_operator buyer.shipping_methods.length, :>, 0
    end

    test 'has many shipping organizations through shipping methods' do
      buyer = create(:oroshi_buyer, :with_orders)
      assert_operator buyer.shipping_organizations.length, :>, 0
    end

    test 'has many orders' do
      buyer = create(:oroshi_buyer, :with_orders)
      assert_operator buyer.orders.length, :>, 0
    end
  end
end
