# frozen_string_literal: true

require "test_helper"

class Oroshi::InvoiceJobTest < ActiveJob::TestCase
  setup do
    @message = create(:message)
    @invoice = instance_double("Oroshi::Invoice", id: 1, start_date: Date.new(2025, 10, 1), end_date: Date.new(2025, 10, 31), invoice_layout: "standard", invoice_date: Date.new(2025, 10, 31))
    @supplier_org = instance_double("Oroshi::SupplierOrganization", id: 1, entity_name: "Test Supplier")
    @invoices_attachment = instance_double("ActiveStorage::Attached::Many")
    @invoice_record = instance_double("ActiveStorage::Attachment", id: 1, save!: true)
    @oroshi_invoice = instance_double("OroshiInvoice", render: "PDF content")
    @join = instance_double("InvoiceSupplierOrganization", supplier_organization: @supplier_org, invoices: @invoices_attachment)

    # Stub Message.find
    allow(Message).to receive(:find).with(@message.id).and_return(@message)

    # Stub Oroshi::Invoice class without loading Oroshi models
    invoice_class = class_double("Oroshi::Invoice").as_stubbed_const
    allow(invoice_class).to receive(:find).with(@invoice.id).and_return(@invoice)
    allow(@invoice).to receive(:invoice_supplier_organizations).and_return([ @join ])

    # Stub join methods
    allow(@join).to receive(:transaction).and_yield
    allow(@invoices_attachment).to receive(:purge)
    allow(@join).to receive(:update!)
    allow(@join).to receive(:completed=)
    allow(@invoices_attachment).to receive(:attach).and_return([ @invoice_record ])
    allow(@join).to receive(:invoices).and_return(@invoices_attachment)

    # Stub OroshiInvoice PDF generation
    oroshi_invoice_class = class_double("OroshiInvoice").as_stubbed_const
    allow(oroshi_invoice_class).to receive(:new).and_return(@oroshi_invoice)
  end

  test "finds the invoice and message" do
    # Already stubbed in setup
    expect(@message).to receive(:update).with(state: true, message: "\u4F9B\u7D66\u6599\u4ED5\u5207\u308A\u66F8\u4F5C\u6210\u5B8C\u4E86")
    Oroshi::InvoiceJob.perform_now(@invoice.id, @message.id)
  end

  test "processes invoice_supplier_organizations" do
    expect(@invoice).to receive(:invoice_supplier_organizations)
    Oroshi::InvoiceJob.perform_now(@invoice.id, @message.id)
  end

  test "resets join (purges invoices and resets passwords)" do
    expect(@invoices_attachment).to receive(:purge)
    expect(@join).to receive(:update!).with(passwords: {})
    expect(@join).to receive(:completed=).with(false)
    Oroshi::InvoiceJob.perform_now(@invoice.id, @message.id)
  end

  test "creates PDFs for both organization and supplier formats" do
    expect(OroshiInvoice).to receive(:new).twice.and_return(@oroshi_invoice)
    Oroshi::InvoiceJob.perform_now(@invoice.id, @message.id)
  end

  test "attaches PDFs with correct parameters" do
    expect(@invoices_attachment).to receive(:attach).twice
    Oroshi::InvoiceJob.perform_now(@invoice.id, @message.id)
  end

  test "updates join with passwords and completion status" do
    expect(@join).to receive(:update!).with(hash_including(:passwords, completed: true))
    Oroshi::InvoiceJob.perform_now(@invoice.id, @message.id)
  end

  test "updates message on completion" do
    Oroshi::InvoiceJob.perform_now(@invoice.id, @message.id)
    @message.reload
    assert_equal true, @message.state
    assert_equal "\u4F9B\u7D66\u6599\u4ED5\u5207\u308A\u66F8\u4F5C\u6210\u5B8C\u4E86", @message.message
  end
end
