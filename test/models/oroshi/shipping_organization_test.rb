# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class ShippingOrganizationTest < ActiveSupport::TestCase
    def setup
      @shipping_organization = build(:oroshi_shipping_organization)
    end

    test 'is valid with valid attributes' do
      assert @shipping_organization.valid?
    end

    # Validations
    test 'is not valid without a name' do
      @shipping_organization.name = nil
      assert_not @shipping_organization.valid?
    end

    test 'is not valid without a handle' do
      @shipping_organization.handle = nil
      assert_not @shipping_organization.valid?
    end

    # Associations
    test 'has many shipping methods' do
      buyers = create_list(:oroshi_buyer, rand(1..3))
      shipping_organization = create(:oroshi_shipping_organization, buyers: buyers)
      assert_operator shipping_organization.shipping_methods.length, :>, 0
    end

    test 'has many buyers through shipping methods' do
      buyers = create_list(:oroshi_buyer, rand(1..3))
      shipping_organization = create(:oroshi_shipping_organization, buyers: buyers)
      assert_operator shipping_organization.buyers.length, :>, 0
    end
  end
end
