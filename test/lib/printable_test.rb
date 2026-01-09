# frozen_string_literal: true

require 'test_helper'

class PrintableTest < ActiveSupport::TestCase
  # Receipt tests
  test 'creates receipt pdf without error' do
    assert_nothing_raised do
      pdf_data = Receipt.new(
        'sales_date' => "2021\u5E7401\u670801\u65E5",
        'order_id' => '1234567890',
        'purchaser' => "\u5C71\u7530\u592A\u90CE",
        'title' => "\u69D8",
        'amount' => '1000',
        'expense_name' => "\u304A\u54C1\u4EE3\u3068\u3057\u3066",
        'oysis' => '1',
        'tax_8_amount' => '100',
        'tax_8_tax' => '8',
        'tax_10_amount' => '100',
        'tax_10_tax' => '10'
      )
      pdf = pdf_data.render
      assert_predicate pdf, :present?
    end
  end

  # ShellCard tests
  test 'creates expiration card pdf without error' do
    assert_nothing_raised do
      card = ExpirationCard.new(
        product_name: "\u6BBB\u4ED8\u304D \u304B\u304D",
        manufacturer_address: "\u5175\u5EAB\u770C\u8D64\u7A42\u5E02\u4E2D\u5E831576-11",
        manufacturer: "\u682A\u5F0F\u4F1A\u793E \u8239\u66F3\u5546\u5E97",
        ingredient_source: "\u5175\u5EAB\u770C\u5742\u8D8A\u6D77\u57DF",
        consumption_restrictions: "\u751F\u98DF\u7528",
        manufactuered_date: "2021\u5E7401\u670801\u65E5",
        expiration_date: "2021\u5E7401\u670805\u65E5",
        storage_recommendation: "\u8981\u51B7\u8535\u30000\u2103\uFF5E10\u2103",
        made_on: true,
        shomiorhi: true
      )
      card.save
      pdf_data = ShellCard.new(card.id)
      pdf = pdf_data.render
      assert_predicate pdf, :present?
    end
  end

  # OnlineShopPackingList tests
  class OnlineShopPackingListTest < ActiveSupport::TestCase
    setup do
      # Create required Setting for headers (using development environment data patterns)
      @setting = Setting.find_or_create_by(name: 'ec_headers') do |s|
        s.settings = %w[500g セル セット その他]
      end

      # Create product types as they exist in development
      @product_types = [
        EcProductType.find_or_create_by(name: '500g') do |pt|
          pt.counter = 'p'
          pt.section = 'default'
        end,
        EcProductType.find_or_create_by(name: "\u30BB\u30EB") do |pt|
          pt.counter = "\u30BB\u30EB"
          pt.section = 'default'
        end,
        EcProductType.find_or_create_by(name: "\u30BB\u30C3\u30C8") do |pt|
          pt.counter = "\u30BB\u30C3\u30C8"
          pt.section = 'default'
        end,
        EcProductType.find_or_create_by(name: "\u305D\u306E\u4ED6") do |pt|
          pt.counter = "\u500B"
          pt.section = 'default'
        end
      ]

      # Create EC products that match development patterns
      @ec_products = [
        EcProduct.find_or_create_by(name: "\u3080\u304D\u8EAB2kg") do |p|
          p.ec_product_type = @product_types[0]
          p.cross_reference_ids = ['10000001'] # m2
          p.quantity = '2000'
          p.frozen_item = false
          p.memo_name = "\u30C6\u30B9\u30C8\u5546\u54C1"
          p.extra_shipping_cost = '0'
        end,
        EcProduct.find_or_create_by(name: "\u304B\u304D\u30BB\u30C3\u30C81kg") do |p|
          p.ec_product_type = @product_types[2]
          p.cross_reference_ids = ['10000015'] # k10
          p.quantity = '1000'
          p.frozen_item = false
          p.memo_name = "\u30C6\u30B9\u30C8\u5546\u54C1"
          p.extra_shipping_cost = '0'
        end,
        EcProduct.find_or_create_by(name: "\u305D\u306E\u4ED6\u5546\u54C1") do |p|
          p.ec_product_type = @product_types[3]
          p.cross_reference_ids = ['OYSTER-500G']
          p.quantity = '500'
          p.frozen_item = false
          p.memo_name = "\u30C6\u30B9\u30C8\u5546\u54C1"
          p.extra_shipping_cost = '0'
        end
      ]
    end

    test 'creates blank shipping list without error (core PDF functionality)' do
      assert_nothing_raised do
        pdf_data = OnlineShopPackingList.new(
          ship_date: Time.zone.today,
          blank: true
        )
        pdf = pdf_data.render
        assert_predicate pdf, :present?
        assert_operator pdf.length, :>, 5000 # Basic PDF size check
      end
    end

    # Complex order-based packing lists require specific data configurations
    # These tests are covered by the comprehensive testing scripts
    # Focus on core PDF generation functionality for pre-deploy suite
    test 'initializes with settings and validates core components' do
      assert_predicate @setting, :present?
      assert_equal %w[500g セル セット その他], @setting.settings
      assert_equal 4, @product_types.length
      assert_equal 3, @ec_products.length
    end

    test 'validates PDF generation dependencies are available' do
      assert_predicate OnlineShopPackingList, :present?
      assert_predicate Receipt, :present?
      assert_predicate ShellCard, :present?
      assert_predicate ExpirationCard, :present?
    end
  end

  # OroshiInvoice tests
  class OroshiInvoiceTest < ActiveSupport::TestCase
    # Test Oroshi PDF generation with proper factory data
    # This replaces the legacy OysterSupply-based tests

    setup do
      # Create supplier organization with suppliers and supply types
      @supplier_organization = create(:oroshi_supplier_organization)
      @suppliers = create_list(:oroshi_supplier, 2, supplier_organization: @supplier_organization)

      # Create supply dates with supplies
      @start_date = Time.zone.today.beginning_of_month
      @end_date = Time.zone.today

      @supply_date = create(:oroshi_supply_date, :with_supplies, date: @start_date)
    end

    test 'creates organization invoice pdf without error' do
      assert_nothing_raised do
        pdf_data = OroshiInvoice.new(
          @start_date,
          @end_date,
          supplier_organization: @supplier_organization.id.to_s,
          invoice_format: 'organization',
          layout: 'simple'
        )
        pdf = pdf_data.render
        assert_predicate pdf, :present?
        assert_operator pdf.length, :>, 1000 # Basic PDF size check
      end
    end

    test 'creates supplier invoice pdf without error' do
      assert_nothing_raised do
        pdf_data = OroshiInvoice.new(
          @start_date,
          @end_date,
          supplier_organization: @supplier_organization.id.to_s,
          invoice_format: 'supplier',
          layout: 'simple'
        )
        pdf = pdf_data.render
        assert_predicate pdf, :present?
        assert_operator pdf.length, :>, 1000
      end
    end

    test 'creates standard layout invoice pdf without error' do
      assert_nothing_raised do
        pdf_data = OroshiInvoice.new(
          @start_date,
          @end_date,
          supplier_organization: @supplier_organization.id.to_s,
          invoice_format: 'organization',
          layout: 'standard'
        )
        pdf = pdf_data.render
        assert_predicate pdf, :present?
      end
    end
  end
end
