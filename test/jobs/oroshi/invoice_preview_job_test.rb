# frozen_string_literal: true

require "test_helper"

class Oroshi::InvoicePreviewJobTest < ActiveJob::TestCase
  setup do
    @message = create(:message, data: {})
    @start_date = Date.new(2025, 10, 1)
    @end_date = Date.new(2025, 10, 31)
    @supplier_organization_id = 1
    @invoice_format = "organization"
    @layout = "standard"
    @supplier_org = instance_double("Oroshi::SupplierOrganization", entity_name: "Test Supplier")
    @oroshi_invoice = instance_double("OroshiInvoice", render: "PDF content")

    # Stub Oroshi::SupplierOrganization
    supplier_org_class = class_double("Oroshi::SupplierOrganization").as_stubbed_const
    allow(supplier_org_class).to receive(:find).with(@supplier_organization_id).and_return(@supplier_org)

    # Stub OroshiInvoice
    oroshi_invoice_class = class_double("OroshiInvoice").as_stubbed_const
    allow(oroshi_invoice_class).to receive(:new).and_return(@oroshi_invoice)
  end

  # with Date objects tests
  test "creates OroshiInvoice with correct parameters" do
    expect(OroshiInvoice).to receive(:new).with(
      @start_date,
      @end_date,
      supplier_organization: @supplier_organization_id,
      invoice_format: @invoice_format,
      layout: @layout
    )
    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
  end

  test "renders the PDF" do
    expect(@oroshi_invoice).to receive(:render)
    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
  end

  test "sets filename in message data" do
    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_includes @message.data[:filename], "Test Supplier"
    assert_includes @message.data[:filename], "2025-10-01"
    assert_includes @message.data[:filename], "2025-10-31"
  end

  test "attaches PDF to message" do
    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert @message.stored_file.attached?
  end

  test "updates message on completion" do
    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_equal true, @message.state
    assert_equal "\u4F9B\u7D66\u6599\u4ED5\u5207\u308A\u66F8\u30D7\u30EC\u30D3\u30E5\u30FC\u4F5C\u6210\u5B8C\u4E86", @message.message
  end

  # with string dates tests
  test "parses string dates correctly" do
    expect(OroshiInvoice).to receive(:new).with(
      @start_date,
      @end_date,
      supplier_organization: @supplier_organization_id,
      invoice_format: @invoice_format,
      layout: @layout
    )
    Oroshi::InvoicePreviewJob.perform_now("2025-10-01", "2025-10-31", @supplier_organization_id, @invoice_format, @layout, @message.id)
  end

  test "creates PDF with parsed dates" do
    Oroshi::InvoicePreviewJob.perform_now("2025-10-01", "2025-10-31", @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert @message.stored_file.attached?
  end

  # filename generation tests
  test "includes entity name from supplier organization" do
    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_includes @message.data[:filename], "Test Supplier"
  end

  test "includes date range" do
    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_match(/2025-10-01.*2025-10-31/, @message.data[:filename])
  end

  test "includes invoice format" do
    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_includes @message.data[:filename], "organization"
  end

  test "includes timestamp" do
    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_match(/\[\d{14}\]\.pdf/, @message.data[:filename])
  end
end
