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
  end

  test "creates OroshiInvoice with correct parameters and attaches PDF" do
    supplier_org = stub(entity_name: "Test Supplier")
    oroshi_invoice = stub(render: "PDF content")

    Oroshi::SupplierOrganization.stubs(:find).with(@supplier_organization_id).returns(supplier_org)
    OroshiInvoice.expects(:new).with(
      @start_date,
      @end_date,
      supplier_organization: @supplier_organization_id,
      invoice_format: @invoice_format,
      layout: @layout
    ).returns(oroshi_invoice)

    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert @message.stored_file.attached?
  end

  test "sets filename in message data" do
    supplier_org = stub(entity_name: "Test Supplier")
    oroshi_invoice = stub(render: "PDF content")

    Oroshi::SupplierOrganization.stubs(:find).with(@supplier_organization_id).returns(supplier_org)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_includes @message.data[:filename], "Test Supplier"
    assert_includes @message.data[:filename], "2025-10-01"
    assert_includes @message.data[:filename], "2025-10-31"
  end

  test "updates message on completion" do
    supplier_org = stub(entity_name: "Test Supplier")
    oroshi_invoice = stub(render: "PDF content")

    Oroshi::SupplierOrganization.stubs(:find).with(@supplier_organization_id).returns(supplier_org)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_equal true, @message.state
    assert_equal "供給料仕切り書プレビュー作成完了", @message.message
  end

  test "parses string dates correctly" do
    supplier_org = stub(entity_name: "Test Supplier")
    oroshi_invoice = stub(render: "PDF content")

    Oroshi::SupplierOrganization.stubs(:find).with(@supplier_organization_id).returns(supplier_org)
    OroshiInvoice.expects(:new).with(
      @start_date,
      @end_date,
      supplier_organization: @supplier_organization_id,
      invoice_format: @invoice_format,
      layout: @layout
    ).returns(oroshi_invoice)

    Oroshi::InvoicePreviewJob.perform_now("2025-10-01", "2025-10-31", @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert @message.stored_file.attached?
  end

  test "includes entity name from supplier organization" do
    supplier_org = stub(entity_name: "Test Supplier")
    oroshi_invoice = stub(render: "PDF content")

    Oroshi::SupplierOrganization.stubs(:find).with(@supplier_organization_id).returns(supplier_org)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_includes @message.data[:filename], "Test Supplier"
  end

  test "includes date range in filename" do
    supplier_org = stub(entity_name: "Test Supplier")
    oroshi_invoice = stub(render: "PDF content")

    Oroshi::SupplierOrganization.stubs(:find).with(@supplier_organization_id).returns(supplier_org)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_match(/2025-10-01.*2025-10-31/, @message.data[:filename])
  end

  test "includes invoice format in filename" do
    supplier_org = stub(entity_name: "Test Supplier")
    oroshi_invoice = stub(render: "PDF content")

    Oroshi::SupplierOrganization.stubs(:find).with(@supplier_organization_id).returns(supplier_org)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_includes @message.data[:filename], "organization"
  end

  test "includes timestamp in filename" do
    supplier_org = stub(entity_name: "Test Supplier")
    oroshi_invoice = stub(render: "PDF content")

    Oroshi::SupplierOrganization.stubs(:find).with(@supplier_organization_id).returns(supplier_org)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoicePreviewJob.perform_now(@start_date, @end_date, @supplier_organization_id, @invoice_format, @layout, @message.id)
    @message.reload
    assert_match(/\[\d{14}\]\.pdf/, @message.data[:filename])
  end
end
