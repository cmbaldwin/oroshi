# frozen_string_literal: true

require "test_helper"

class Oroshi::InvoiceTest < ActiveSupport::TestCase
  def setup
    @invoice = build(:oroshi_invoice)
  end

  test "is valid with valid attributes" do
    assert @invoice.valid?
  end

  # Validations
  test "is not valid without a start_date" do
    @invoice.start_date = nil
    assert_not @invoice.valid?
  end

  test "is not valid without an end_date" do
    @invoice.end_date = nil
    assert_not @invoice.valid?
  end

  test "is not valid without send_email" do
    @invoice.send_email = nil
    assert_not @invoice.valid?
  end

  test "is not valid without an invoice_layout" do
    @invoice.invoice_layout = nil
    assert_not @invoice.valid?
  end

  test "is not valid without send_at if send_email is true" do
    @invoice.send_email = true
    @invoice.send_at = nil
    assert_not @invoice.valid?
  end

  test "is valid without send_at if send_email is false" do
    @invoice.send_email = false
    @invoice.send_at = nil
    assert @invoice.valid?
  end

  test "is not valid without at least one supplier organization" do
    @invoice.supplier_organizations = []
    assert_not @invoice.valid?
  end

  # Associations
  test "has supply dates" do
    invoice = create(:oroshi_invoice, :with_supply_dates)
    assert_operator invoice.supply_dates.length, :>, 0
  end

  test "has supplies" do
    invoice = create(:oroshi_invoice, :with_supply_dates)
    assert_operator invoice.supplies.length, :>, 0
  end

  test "has supplier organizations" do
    invoice = create(:oroshi_invoice, :with_supply_dates)
    assert_operator invoice.supplier_organizations.length, :>, 0
  end

  # Callbacks
  test "locks supplies after create" do
    invoice = create(:oroshi_invoice, :with_supply_dates)
    invoice_supply_dates = Oroshi::Invoice::SupplyDate.where(invoice: invoice)
    # expect the invoice_supply_dates join to exist
    assert_not invoice_supply_dates.count.zero?
    supplies = invoice_supply_dates.map(&:supplies_with_invoice_supplier_organizations).flatten
    # only one invoice and supplies so all supplies should be locked
    assert_not supplies.count.zero?
  end

  test "locks and unlocks supplies after create and destroy" do
    # Create supplier org and invoice with that org
    supplier_org = create(:oroshi_supplier_organization)
    invoice = create(:oroshi_invoice)
    invoice.supplier_organizations << supplier_org

    # Create supply with supplier from same org
    supplier = create(:oroshi_supplier, supplier_organization: supplier_org)
    supply_date = create(:oroshi_supply_date)
    supply = create(:oroshi_supply,
                    supply_date: supply_date,
                    supplier: supplier,
                    locked: false)

    # Add supply_date to invoice, which should lock matching supplies
    invoice_supply_date = Oroshi::Invoice::SupplyDate.create!(
      invoice: invoice,
      supply_date: supply_date
    )

    assert supply.reload.locked

    # Destroy the join record, which should unlock supplies
    invoice_supply_date.destroy

    assert_not supply.reload.locked
  end

  test "does not destroy invoice if sent" do
    invoice = create(:oroshi_invoice, :with_supply_dates, sent_at: Time.zone.now)
    assert_no_difference -> { Oroshi::Invoice.count } do
      invoice.destroy
    end
  end
end
