# frozen_string_literal: true

require "test_helper"

class PrintableTest < ActiveSupport::TestCase
  # Receipt and ShellCard/ExpirationCard tests removed - these classes
  # (Receipt, ShellCard, ExpirationCard) are parent-app-specific models
  # that live in funabiki-online, not in the Oroshi engine.
  # They should be tested in the parent app's test suite.

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

    test "creates organization invoice pdf without error" do
      assert_nothing_raised do
        pdf_data = OroshiInvoice.new(
          @start_date,
          @end_date,
          supplier_organization: @supplier_organization.id.to_s,
          invoice_format: "organization",
          layout: "simple"
        )
        pdf = pdf_data.render
        assert_predicate pdf, :present?
        assert_operator pdf.length, :>, 1000 # Basic PDF size check
      end
    end

    test "creates supplier invoice pdf without error" do
      assert_nothing_raised do
        pdf_data = OroshiInvoice.new(
          @start_date,
          @end_date,
          supplier_organization: @supplier_organization.id.to_s,
          invoice_format: "supplier",
          layout: "simple"
        )
        pdf = pdf_data.render
        assert_predicate pdf, :present?
        assert_operator pdf.length, :>, 1000
      end
    end

    test "creates standard layout invoice pdf without error" do
      assert_nothing_raised do
        pdf_data = OroshiInvoice.new(
          @start_date,
          @end_date,
          supplier_organization: @supplier_organization.id.to_s,
          invoice_format: "organization",
          layout: "standard"
        )
        pdf = pdf_data.render
        assert_predicate pdf, :present?
      end
    end
  end
end
