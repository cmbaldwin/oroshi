# frozen_string_literal: true

require "test_helper"

class Oroshi::InvoiceJobTest < ActiveJob::TestCase
  setup do
    @message = create(:message)
  end

  test "finds invoice and message and updates message on completion" do
    supplier_org = stub(id: 1, entity_name: "Test Supplier")
    invoices_attachment = stub
    invoice_record = stub(id: 1)
    invoice_record.stubs(:save!).returns(true)
    oroshi_invoice = stub(render: "PDF content")

    join = stub(
      supplier_organization: supplier_org,
      invoices: invoices_attachment
    )
    join.stubs(:transaction).yields
    join.stubs(:update!)
    join.stubs(:completed=)

    invoice = stub(
      id: 1,
      start_date: Date.new(2025, 10, 1),
      end_date: Date.new(2025, 10, 31),
      invoice_layout: "standard",
      invoice_date: Date.new(2025, 10, 31),
      invoice_supplier_organizations: [join]
    )

    invoices_attachment.stubs(:purge)
    invoices_attachment.stubs(:attach).returns([invoice_record])

    Oroshi::Invoice.stubs(:find).with(1).returns(invoice)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoiceJob.perform_now(1, @message.id)

    @message.reload
    assert_equal true, @message.state
    assert_equal "供給料仕切り書作成完了", @message.message
  end

  test "processes invoice_supplier_organizations" do
    supplier_org = stub(id: 1, entity_name: "Test Supplier")
    invoices_attachment = stub
    invoice_record = stub(id: 1)
    invoice_record.stubs(:save!).returns(true)
    oroshi_invoice = stub(render: "PDF content")

    join = stub(
      supplier_organization: supplier_org,
      invoices: invoices_attachment
    )
    join.stubs(:transaction).yields
    join.stubs(:update!)
    join.stubs(:completed=)

    invoice = stub(
      id: 1,
      start_date: Date.new(2025, 10, 1),
      end_date: Date.new(2025, 10, 31),
      invoice_layout: "standard",
      invoice_date: Date.new(2025, 10, 31)
    )
    invoice.expects(:invoice_supplier_organizations).returns([join])

    invoices_attachment.stubs(:purge)
    invoices_attachment.stubs(:attach).returns([invoice_record])

    Oroshi::Invoice.stubs(:find).returns(invoice)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoiceJob.perform_now(1, @message.id)
  end

  test "resets join by purging invoices and resetting passwords" do
    supplier_org = stub(id: 1, entity_name: "Test Supplier")
    invoices_attachment = stub
    invoice_record = stub(id: 1)
    invoice_record.stubs(:save!).returns(true)
    oroshi_invoice = stub(render: "PDF content")

    join = stub(
      supplier_organization: supplier_org,
      invoices: invoices_attachment
    )
    join.stubs(:transaction).yields
    join.stubs(:update!)
    join.expects(:completed=).with(false)

    invoice = stub(
      id: 1,
      start_date: Date.new(2025, 10, 1),
      end_date: Date.new(2025, 10, 31),
      invoice_layout: "standard",
      invoice_date: Date.new(2025, 10, 31),
      invoice_supplier_organizations: [join]
    )

    invoices_attachment.expects(:purge)
    invoices_attachment.stubs(:attach).returns([invoice_record])

    Oroshi::Invoice.stubs(:find).returns(invoice)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoiceJob.perform_now(1, @message.id)
  end

  test "creates PDFs for both organization and supplier formats" do
    supplier_org = stub(id: 1, entity_name: "Test Supplier")
    invoices_attachment = stub
    invoice_record = stub(id: 1)
    invoice_record.stubs(:save!).returns(true)
    oroshi_invoice = stub(render: "PDF content")

    join = stub(
      supplier_organization: supplier_org,
      invoices: invoices_attachment
    )
    join.stubs(:transaction).yields
    join.stubs(:update!)
    join.stubs(:completed=)

    invoice = stub(
      id: 1,
      start_date: Date.new(2025, 10, 1),
      end_date: Date.new(2025, 10, 31),
      invoice_layout: "standard",
      invoice_date: Date.new(2025, 10, 31),
      invoice_supplier_organizations: [join]
    )

    invoices_attachment.stubs(:purge)
    invoices_attachment.stubs(:attach).returns([invoice_record])

    Oroshi::Invoice.stubs(:find).returns(invoice)
    OroshiInvoice.expects(:new).twice.returns(oroshi_invoice)

    Oroshi::InvoiceJob.perform_now(1, @message.id)
  end

  test "attaches PDFs twice (organization and supplier formats)" do
    supplier_org = stub(id: 1, entity_name: "Test Supplier")
    invoices_attachment = stub
    invoice_record = stub(id: 1)
    invoice_record.stubs(:save!).returns(true)
    oroshi_invoice = stub(render: "PDF content")

    join = stub(
      supplier_organization: supplier_org,
      invoices: invoices_attachment
    )
    join.stubs(:transaction).yields
    join.stubs(:update!)
    join.stubs(:completed=)

    invoice = stub(
      id: 1,
      start_date: Date.new(2025, 10, 1),
      end_date: Date.new(2025, 10, 31),
      invoice_layout: "standard",
      invoice_date: Date.new(2025, 10, 31),
      invoice_supplier_organizations: [join]
    )

    invoices_attachment.stubs(:purge)
    invoices_attachment.expects(:attach).twice.returns([invoice_record])

    Oroshi::Invoice.stubs(:find).returns(invoice)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoiceJob.perform_now(1, @message.id)
  end

  test "updates join with passwords and completion status" do
    supplier_org = stub(id: 1, entity_name: "Test Supplier")
    invoices_attachment = stub
    invoice_record = stub(id: 1)
    invoice_record.stubs(:save!).returns(true)
    oroshi_invoice = stub(render: "PDF content")

    join = stub(
      supplier_organization: supplier_org,
      invoices: invoices_attachment
    )
    join.stubs(:transaction).yields
    join.stubs(:update!)
    join.stubs(:completed=)
    join.expects(:update!).with(has_entries(completed: true))

    invoice = stub(
      id: 1,
      start_date: Date.new(2025, 10, 1),
      end_date: Date.new(2025, 10, 31),
      invoice_layout: "standard",
      invoice_date: Date.new(2025, 10, 31),
      invoice_supplier_organizations: [join]
    )

    invoices_attachment.stubs(:purge)
    invoices_attachment.stubs(:attach).returns([invoice_record])

    Oroshi::Invoice.stubs(:find).returns(invoice)
    OroshiInvoice.stubs(:new).returns(oroshi_invoice)

    Oroshi::InvoiceJob.perform_now(1, @message.id)
  end
end
