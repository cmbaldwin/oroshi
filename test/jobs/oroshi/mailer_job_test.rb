# frozen_string_literal: true

require "test_helper"

class Oroshi::MailerJobTest < ActiveJob::TestCase
  setup do
    @message = create(:message)
  end

  # Test perform with invoice_id and message_id
  test "finds invoice and message when both IDs provided" do
    invoice = stub(
      id: 1,
      sent_at: nil,
      invoice_supplier_organizations: [],
      errors: stub(full_messages: [])
    )
    invoice.stubs(:sent_at=)
    invoice.stubs(:save).returns(true)

    Oroshi::Invoice.expects(:find).with(1).returns(invoice)
    Message.expects(:find).with(@message.id).returns(@message)

    Oroshi::MailerJob.perform_now(1, @message.id)
  end

  test "sends notifications and marks invoice as sent on success" do
    supplier_org = stub(id: 1, entity_name: "Supplier 1", email: "supplier@example.com")
    join = stub(
      id: 1,
      completed: true,
      sent_at: nil,
      supplier_organization: supplier_org,
      errors: stub(full_messages: [])
    )
    join.stubs(:sent_at=)
    join.stubs(:completed=)
    join.stubs(:save).returns(true)

    invoice = stub(
      id: 1,
      sent_at: nil,
      invoice_supplier_organizations: [join],
      errors: stub(full_messages: [])
    )
    invoice.stubs(:sent_at=)
    invoice.stubs(:save).returns(true)

    mailer_double = stub(deliver_now: true)

    Oroshi::Invoice.stubs(:find).returns(invoice)
    Message.stubs(:find).returns(@message)
    Oroshi::InvoiceMailer.stubs(:invoice_notification).returns(mailer_double)

    Oroshi::MailerJob.perform_now(1, @message.id)

    @message.reload
    assert_equal true, @message.state
    assert_equal "メールを送信しました。", @message.message
  end

  test "updates message with failure status when supplier org is incomplete" do
    supplier_org = stub(id: 1, entity_name: "Supplier 1", email: "supplier@example.com")
    join = stub(
      id: 1,
      completed: false,  # Incomplete!
      sent_at: nil,
      supplier_organization: supplier_org,
      errors: stub(full_messages: [])
    )

    invoice = stub(
      id: 1,
      sent_at: nil,
      invoice_supplier_organizations: [join],
      errors: stub(full_messages: [])
    )
    invoice.stubs(:sent_at=)
    invoice.stubs(:save).returns(true)

    Oroshi::Invoice.stubs(:find).returns(invoice)
    Message.stubs(:find).returns(@message)
    Rails.logger.stubs(:error)

    Oroshi::MailerJob.perform_now(1, @message.id)

    @message.reload
    assert_equal false, @message.state
    assert_equal "メールの送信に失敗しました。", @message.message
  end

  test "succeeds even when supplier has no email (sends to company email)" do
    supplier_org = stub(id: 1, entity_name: "相生", email: "")
    join = stub(
      id: 1,
      completed: true,
      sent_at: nil,
      supplier_organization: supplier_org,
      errors: stub(full_messages: [])
    )
    join.stubs(:sent_at=)
    join.stubs(:completed=)
    join.stubs(:save).returns(true)

    invoice = stub(
      id: 1,
      sent_at: nil,
      invoice_supplier_organizations: [join],
      errors: stub(full_messages: [])
    )
    invoice.stubs(:sent_at=)
    invoice.stubs(:save).returns(true)

    mailer_double = stub(deliver_now: true)

    Oroshi::Invoice.stubs(:find).returns(invoice)
    Message.stubs(:find).returns(@message)
    Oroshi::InvoiceMailer.stubs(:invoice_notification).returns(mailer_double)
    # Stub logger to allow info logging (job logs when supplier has no email)
    Rails.logger.stubs(:info)

    Oroshi::MailerJob.perform_now(1, @message.id)

    @message.reload
    assert_equal true, @message.state
    assert_equal "メールを送信しました。", @message.message
  end

  # Test perform with no arguments (send all unsent)
  test "finds all unsent invoices when no arguments provided" do
    Oroshi::Invoice.expects(:unsent).returns([])

    Oroshi::MailerJob.perform_now
  end

  test "processes each unsent invoice" do
    supplier_org = stub(id: 1, entity_name: "Supplier 1", email: "supplier@example.com")
    join1 = stub(
      id: 1,
      completed: true,
      sent_at: nil,
      supplier_organization: supplier_org,
      errors: stub(full_messages: [])
    )
    join1.stubs(:sent_at=)
    join1.stubs(:completed=)
    join1.stubs(:save).returns(true)

    join2 = stub(
      id: 2,
      completed: true,
      sent_at: nil,
      supplier_organization: supplier_org,
      errors: stub(full_messages: [])
    )
    join2.stubs(:sent_at=)
    join2.stubs(:completed=)
    join2.stubs(:save).returns(true)

    invoice1 = stub(
      id: 1,
      sent_at: nil,
      invoice_supplier_organizations: [join1],
      errors: stub(full_messages: [])
    )
    invoice1.stubs(:sent_at=)
    invoice1.stubs(:save).returns(true)

    invoice2 = stub(
      id: 2,
      sent_at: nil,
      invoice_supplier_organizations: [join2],
      errors: stub(full_messages: [])
    )
    invoice2.stubs(:sent_at=)
    invoice2.stubs(:save).returns(true)

    mailer_double = stub(deliver_now: true)

    Oroshi::Invoice.stubs(:unsent).returns([invoice1, invoice2])
    Oroshi::InvoiceMailer.stubs(:invoice_notification).returns(mailer_double)

    # Should call save on both invoices
    invoice1.expects(:save).at_least_once
    invoice2.expects(:save).at_least_once

    Oroshi::MailerJob.perform_now
  end

  test "calls send_all_unsent when arguments are nil" do
    Oroshi::Invoice.expects(:unsent).returns([])

    Oroshi::MailerJob.perform_now(nil, nil)
  end
end
