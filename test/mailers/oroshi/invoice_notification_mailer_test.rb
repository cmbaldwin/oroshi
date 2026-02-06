# frozen_string_literal: true

require "test_helper"

class Oroshi::InvoiceNotificationMailerTest < ActionMailer::TestCase
  test "invoice_notification renders the headers" do
    invoice = create(:oroshi_invoice, :with_supply_dates)
    invoice_supplier_organization = invoice.invoice_supplier_organizations.first
    mail = Oroshi::InvoiceMailer.invoice_notification(invoice_supplier_organization.id)

    assert_includes mail.subject, invoice_supplier_organization.supplier_organization.micro_region
    assert_equal [ invoice_supplier_organization.supplier_organization.email ], mail.to
    expected_from = Setting.find_by(name: "oroshi_company_settings")&.settings&.dig("mail") || ENV.fetch("MAIL_SENDER", nil)
    if expected_from
      assert_equal [ expected_from ], mail.from
    else
      assert_nil mail.from
    end
  end

  test "invoice_notification renders the body" do
    invoice = create(:oroshi_invoice, :with_supply_dates)
    invoice_supplier_organization = invoice.invoice_supplier_organizations.first
    mail = Oroshi::InvoiceMailer.invoice_notification(invoice_supplier_organization.id)

    assert_match invoice_supplier_organization.supplier_organization.entity_name, mail.body.encoded
  end
end
