# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class SupplierTest < ActiveSupport::TestCase
    def setup
      @supplier = build(:oroshi_supplier)
    end

    test 'is valid with valid attributes' do
      assert @supplier.valid?
    end

    # Validations
    test 'is not valid without a company_name' do
      @supplier.company_name = nil
      assert_not @supplier.valid?
    end

    test 'is not valid without a supplier_number' do
      @supplier.supplier_number = nil
      assert_not @supplier.valid?
    end

    test 'is not valid without representatives' do
      @supplier.representatives = nil
      assert_not @supplier.valid?
    end

    test 'is not valid without an invoice_number' do
      @supplier.invoice_number = nil
      assert_not @supplier.valid?
    end

    test 'is not valid without a supplier_organization_id' do
      @supplier.supplier_organization_id = nil
      assert_not @supplier.valid?
    end

    test 'is not valid without active' do
      @supplier.active = nil
      assert_not @supplier.valid?
    end

    test 'is not valid if active is not a boolean' do
      @supplier.active = nil
      assert_not @supplier.valid?
    end

    # circled_number method
    test 'returns the circled unicode character for the supplier_number' do
      @supplier.supplier_number = 5
      assert_equal "\u2464", @supplier.circled_number
    end

    test 'returns nil if the supplier_number is not between 1 and 20' do
      @supplier.supplier_number = 21
      assert_nil @supplier.circled_number
    end

    # Association Assignments
    test 'has supplier_organization' do
      supplier = create(:oroshi_supplier)
      assert_instance_of Oroshi::SupplierOrganization, supplier.supplier_organization
    end

    test 'has supply reception times' do
      supplier = create(:oroshi_supplier)
      assert_operator supplier.supply_reception_times.length, :>, 0
    end

    test 'has addresses' do
      supplier = create(:oroshi_supplier)
      assert_operator supplier.addresses.length, :>, 0
    end
  end
end
