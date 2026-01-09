# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class SupplierOrganizationTest < ActiveSupport::TestCase
    def setup
      @supplier_organization = build(:oroshi_supplier_organization)
    end

    # Validations
    test 'is valid with valid attributes' do
      assert @supplier_organization.valid?
    end

    test 'is not valid without an entity_type' do
      @supplier_organization.entity_type = nil
      assert_not @supplier_organization.valid?
    end

    test 'is not valid without an entity_name' do
      @supplier_organization.entity_name = nil
      assert_not @supplier_organization.valid?
    end

    test 'is not valid without a country_id' do
      @supplier_organization.country_id = nil
      assert_not @supplier_organization.valid?
    end

    test 'is not valid without a subregion_id' do
      @supplier_organization.subregion_id = nil
      assert_not @supplier_organization.valid?
    end

    # Association Assignments
    test 'has suppliers' do
      supplier_organization = create(:oroshi_supplier_organization, :with_suppliers)
      assert_operator supplier_organization.suppliers.length, :>, 0
    end

    test 'has supply reception times' do
      supplier_organization = create(:oroshi_supplier_organization, :with_suppliers)
      assert_operator supplier_organization.supply_reception_times.length, :>, 0
    end

    test 'has addresses' do
      supplier_organization = create(:oroshi_supplier_organization, :with_suppliers)
      assert_operator supplier_organization.addresses.length, :>, 0
    end
  end
end
