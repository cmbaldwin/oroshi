# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class MailerJobTest < ActiveJob::TestCase
    setup do
      @message = create(:message)
      @invoice = instance_double('Oroshi::Invoice', id: 1, sent_at: nil, save: true,
                                                    errors: instance_double('ActiveModel::Errors', full_messages: []))
      @supplier_org1 = instance_double('Oroshi::SupplierOrganization', id: 1, entity_name: 'Supplier 1',
                                                                       email: 'supplier1@example.com')
      @supplier_org2 = instance_double('Oroshi::SupplierOrganization', id: 2, entity_name: 'Supplier 2',
                                                                       email: 'supplier2@example.com')
      @join1 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 1, completed: true, sent_at: nil, save: true,
                                                                        'sent_at=': nil, 'completed=': nil,
                                                                        supplier_organization: @supplier_org1,
                                                                        errors: instance_double('ActiveModel::Errors', full_messages: []))
      @join2 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 2, completed: true, sent_at: nil, save: true,
                                                                        'sent_at=': nil, 'completed=': nil,
                                                                        supplier_organization: @supplier_org2,
                                                                        errors: instance_double('ActiveModel::Errors', full_messages: []))
      @mailer_double = double('ActionMailer::MessageDelivery', deliver_now: true)

      # Stub Oroshi::Invoice class
      invoice_class = class_double('Oroshi::Invoice').as_stubbed_const
      allow(invoice_class).to receive(:find).with(@invoice.id).and_return(@invoice)
      allow(invoice_class).to receive(:unsent).and_return([])

      # Stub Message.find
      allow(Message).to receive(:find).with(@message.id).and_return(@message)
      allow(@message).to receive(:state=)
      allow(@message).to receive(:message=)
      allow(@message).to receive(:save)

      # Stub invoice associations
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([@join1, @join2])
      allow(@invoice).to receive(:sent_at=)

      # Stub mailer
      allow(Oroshi::InvoiceMailer).to receive(:invoice_notification).and_return(@mailer_double)
    end

    # perform with invoice_id and message_id tests
    test 'finds the invoice and message' do
      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Oroshi::Invoice, :find).with(@invoice.id)
      assert_received(Message, :find).with(@message.id)
    end

    test 'sends invoice notifications to all supplier organizations' do
      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Oroshi::InvoiceMailer, :invoice_notification).with(@join1.id)
      assert_received(Oroshi::InvoiceMailer, :invoice_notification).with(@join2.id)
    end

    test 'marks each supplier organization as completed and sent' do
      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(@join1, :sent_at=)
      assert_received(@join1, :completed=).with(true)
      assert_received(@join1, :save)

      assert_received(@join2, :sent_at=)
      assert_received(@join2, :completed=).with(true)
      assert_received(@join2, :save)
    end

    test 'marks invoice as sent' do
      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(@invoice, :sent_at=)
      assert_received(@invoice, :save)
    end

    test 'updates message with success status' do
      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(@message, :state=).with(true)
      assert_received(@message, :message=).with("\u30E1\u30FC\u30EB\u3092\u9001\u4FE1\u3057\u307E\u3057\u305F\u3002")
      assert_received(@message, :save)
    end

    # when email delivery fails tests
    test 'updates message with failure status when email delivery fails' do
      error_double = instance_double('ActiveModel::Errors', full_messages: ['Error message'])
      allow(@mailer_double).to receive(:deliver_now).and_return(false)
      allow(@mailer_double).to receive(:errors).and_return(error_double)
      allow(Rails.logger).to receive(:error)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(@message, :state=).with(false)
      assert_received(@message,
                      :message=).with("\u30E1\u30FC\u30EB\u306E\u9001\u4FE1\u306B\u5931\u6557\u3057\u307E\u3057\u305F\u3002")
      assert_received(@message, :save)
    end

    test 'logs the error when email delivery fails' do
      error_double = instance_double('ActiveModel::Errors', full_messages: ['Error message'])
      allow(@mailer_double).to receive(:deliver_now).and_return(false)
      allow(@mailer_double).to receive(:errors).and_return(error_double)
      allow(Rails.logger).to receive(:error)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Rails.logger, :error).at_least(:once)
    end

    test 'does not mark invoice as sent when email delivery fails' do
      error_double = instance_double('ActiveModel::Errors', full_messages: ['Error message'])
      allow(@mailer_double).to receive(:deliver_now).and_return(false)
      allow(@mailer_double).to receive(:errors).and_return(error_double)
      allow(Rails.logger).to receive(:error)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_not_received(@invoice, :sent_at=)
    end

    # when supplier organization is incomplete tests
    test 'logs error and skips sending when supplier organization is incomplete' do
      allow(@join1).to receive(:completed).and_return(false)
      allow(Rails.logger).to receive(:error)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Rails.logger, :error).with(/incomplete invoice_supplier_organization/)
    end

    test 'updates message with failure status when supplier organization is incomplete' do
      allow(@join1).to receive(:completed).and_return(false)
      allow(Rails.logger).to receive(:error)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(@message, :state=).with(false)
      assert_received(@message,
                      :message=).with("\u30E1\u30FC\u30EB\u306E\u9001\u4FE1\u306B\u5931\u6557\u3057\u307E\u3057\u305F\u3002")
    end

    # when supplier organization has no email tests
    test 'logs info about sending to company email when supplier has no email' do
      supplier_org_no_email = instance_double('Oroshi::SupplierOrganization', id: 3, entity_name: "\u76F8\u751F",
                                                                              email: '')
      join_no_email = instance_double('Oroshi::Invoice::SupplierOrganization', id: 3, completed: true, sent_at: nil, save: true,
                                                                               'sent_at=': nil, 'completed=': nil,
                                                                               supplier_organization: supplier_org_no_email,
                                                                               errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([join_no_email, @join2])
      allow(Rails.logger).to receive(:info)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Rails.logger, :info).with(/Sending.*to company email.*相生.*has no email/)
    end

    test 'still sends email (to company instead of supplier) when supplier has no email' do
      supplier_org_no_email = instance_double('Oroshi::SupplierOrganization', id: 3, entity_name: "\u76F8\u751F",
                                                                              email: '')
      join_no_email = instance_double('Oroshi::Invoice::SupplierOrganization', id: 3, completed: true, sent_at: nil, save: true,
                                                                               'sent_at=': nil, 'completed=': nil,
                                                                               supplier_organization: supplier_org_no_email,
                                                                               errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([join_no_email, @join2])
      allow(Rails.logger).to receive(:info)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Oroshi::InvoiceMailer, :invoice_notification).with(join_no_email.id)
    end

    test 'sends to other organizations with valid emails when one has no email' do
      supplier_org_no_email = instance_double('Oroshi::SupplierOrganization', id: 3, entity_name: "\u76F8\u751F",
                                                                              email: '')
      join_no_email = instance_double('Oroshi::Invoice::SupplierOrganization', id: 3, completed: true, sent_at: nil, save: true,
                                                                               'sent_at=': nil, 'completed=': nil,
                                                                               supplier_organization: supplier_org_no_email,
                                                                               errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([join_no_email, @join2])
      allow(Rails.logger).to receive(:info)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Oroshi::InvoiceMailer, :invoice_notification).with(@join2.id)
    end

    test 'updates message with success status when supplier has no email' do
      supplier_org_no_email = instance_double('Oroshi::SupplierOrganization', id: 3, entity_name: "\u76F8\u751F",
                                                                              email: '')
      join_no_email = instance_double('Oroshi::Invoice::SupplierOrganization', id: 3, completed: true, sent_at: nil, save: true,
                                                                               'sent_at=': nil, 'completed=': nil,
                                                                               supplier_organization: supplier_org_no_email,
                                                                               errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([join_no_email, @join2])
      allow(Rails.logger).to receive(:info)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(@message, :state=).with(true)
      assert_received(@message, :message=).with("\u30E1\u30FC\u30EB\u3092\u9001\u4FE1\u3057\u307E\u3057\u305F\u3002")
    end

    test 'marks invoice as sent when supplier has no email' do
      supplier_org_no_email = instance_double('Oroshi::SupplierOrganization', id: 3, entity_name: "\u76F8\u751F",
                                                                              email: '')
      join_no_email = instance_double('Oroshi::Invoice::SupplierOrganization', id: 3, completed: true, sent_at: nil, save: true,
                                                                               'sent_at=': nil, 'completed=': nil,
                                                                               supplier_organization: supplier_org_no_email,
                                                                               errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([join_no_email, @join2])
      allow(Rails.logger).to receive(:info)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(@invoice, :sent_at=)
      assert_received(@invoice, :save)
    end

    # when all supplier organizations have no email tests
    test 'logs info for all organizations being sent to company when all have no email' do
      supplier_org_no_email1 = instance_double('Oroshi::SupplierOrganization', id: 3, entity_name: "\u76F8\u751F",
                                                                               email: '')
      supplier_org_no_email2 = instance_double('Oroshi::SupplierOrganization', id: 4, entity_name: "\u8D64\u7A42",
                                                                               email: nil)
      join_no_email1 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 3, completed: true, sent_at: nil, save: true,
                                                                                'sent_at=': nil, 'completed=': nil,
                                                                                supplier_organization: supplier_org_no_email1,
                                                                                errors: instance_double('ActiveModel::Errors', full_messages: []))
      join_no_email2 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 4, completed: true, sent_at: nil, save: true,
                                                                                'sent_at=': nil, 'completed=': nil,
                                                                                supplier_organization: supplier_org_no_email2,
                                                                                errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([join_no_email1, join_no_email2])
      allow(Rails.logger).to receive(:info)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Rails.logger, :info).with(/Sending.*to company email.*相生.*has no email/)
      assert_received(Rails.logger, :info).with(/Sending.*to company email.*赤穂.*has no email/)
    end

    test 'sends emails to company for all organizations when all have no email' do
      supplier_org_no_email1 = instance_double('Oroshi::SupplierOrganization', id: 3, entity_name: "\u76F8\u751F",
                                                                               email: '')
      supplier_org_no_email2 = instance_double('Oroshi::SupplierOrganization', id: 4, entity_name: "\u8D64\u7A42",
                                                                               email: nil)
      join_no_email1 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 3, completed: true, sent_at: nil, save: true,
                                                                                'sent_at=': nil, 'completed=': nil,
                                                                                supplier_organization: supplier_org_no_email1,
                                                                                errors: instance_double('ActiveModel::Errors', full_messages: []))
      join_no_email2 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 4, completed: true, sent_at: nil, save: true,
                                                                                'sent_at=': nil, 'completed=': nil,
                                                                                supplier_organization: supplier_org_no_email2,
                                                                                errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([join_no_email1, join_no_email2])
      allow(Rails.logger).to receive(:info)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Oroshi::InvoiceMailer, :invoice_notification).with(join_no_email1.id)
      assert_received(Oroshi::InvoiceMailer, :invoice_notification).with(join_no_email2.id)
    end

    test 'marks invoice as sent when all have no email' do
      supplier_org_no_email1 = instance_double('Oroshi::SupplierOrganization', id: 3, entity_name: "\u76F8\u751F",
                                                                               email: '')
      supplier_org_no_email2 = instance_double('Oroshi::SupplierOrganization', id: 4, entity_name: "\u8D64\u7A42",
                                                                               email: nil)
      join_no_email1 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 3, completed: true, sent_at: nil, save: true,
                                                                                'sent_at=': nil, 'completed=': nil,
                                                                                supplier_organization: supplier_org_no_email1,
                                                                                errors: instance_double('ActiveModel::Errors', full_messages: []))
      join_no_email2 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 4, completed: true, sent_at: nil, save: true,
                                                                                'sent_at=': nil, 'completed=': nil,
                                                                                supplier_organization: supplier_org_no_email2,
                                                                                errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([join_no_email1, join_no_email2])
      allow(Rails.logger).to receive(:info)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(@invoice, :sent_at=)
      assert_received(@invoice, :save)
    end

    test 'updates message with success status when all have no email' do
      supplier_org_no_email1 = instance_double('Oroshi::SupplierOrganization', id: 3, entity_name: "\u76F8\u751F",
                                                                               email: '')
      supplier_org_no_email2 = instance_double('Oroshi::SupplierOrganization', id: 4, entity_name: "\u8D64\u7A42",
                                                                               email: nil)
      join_no_email1 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 3, completed: true, sent_at: nil, save: true,
                                                                                'sent_at=': nil, 'completed=': nil,
                                                                                supplier_organization: supplier_org_no_email1,
                                                                                errors: instance_double('ActiveModel::Errors', full_messages: []))
      join_no_email2 = instance_double('Oroshi::Invoice::SupplierOrganization', id: 4, completed: true, sent_at: nil, save: true,
                                                                                'sent_at=': nil, 'completed=': nil,
                                                                                supplier_organization: supplier_org_no_email2,
                                                                                errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(@invoice).to receive(:invoice_supplier_organizations).and_return([join_no_email1, join_no_email2])
      allow(Rails.logger).to receive(:info)

      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(@message, :state=).with(true)
      assert_received(@message, :message=).with("\u30E1\u30FC\u30EB\u3092\u9001\u4FE1\u3057\u307E\u3057\u305F\u3002")
    end

    # perform with no arguments (send all unsent) tests
    test 'finds all unsent invoices' do
      invoice1 = instance_double('Oroshi::Invoice', id: 1, sent_at: nil, save: true, 'sent_at=': nil,
                                                    invoice_supplier_organizations: [@join1], errors: instance_double('ActiveModel::Errors', full_messages: []))
      invoice2 = instance_double('Oroshi::Invoice', id: 2, sent_at: nil, save: true, 'sent_at=': nil,
                                                    invoice_supplier_organizations: [@join2], errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(Oroshi::Invoice).to receive(:unsent).and_return([invoice1, invoice2])

      Oroshi::MailerJob.perform_now

      assert_received(Oroshi::Invoice, :unsent)
    end

    test 'processes each unsent invoice' do
      invoice1 = instance_double('Oroshi::Invoice', id: 1, sent_at: nil, save: true, 'sent_at=': nil,
                                                    invoice_supplier_organizations: [@join1], errors: instance_double('ActiveModel::Errors', full_messages: []))
      invoice2 = instance_double('Oroshi::Invoice', id: 2, sent_at: nil, save: true, 'sent_at=': nil,
                                                    invoice_supplier_organizations: [@join2], errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(Oroshi::Invoice).to receive(:unsent).and_return([invoice1, invoice2])

      Oroshi::MailerJob.perform_now

      assert_received(invoice1, :sent_at=)
      assert_received(invoice1, :save)
      assert_received(invoice2, :sent_at=)
      assert_received(invoice2, :save)
    end

    test 'sends notifications for each invoice' do
      invoice1 = instance_double('Oroshi::Invoice', id: 1, sent_at: nil, save: true, 'sent_at=': nil,
                                                    invoice_supplier_organizations: [@join1], errors: instance_double('ActiveModel::Errors', full_messages: []))
      invoice2 = instance_double('Oroshi::Invoice', id: 2, sent_at: nil, save: true, 'sent_at=': nil,
                                                    invoice_supplier_organizations: [@join2], errors: instance_double('ActiveModel::Errors', full_messages: []))
      allow(Oroshi::Invoice).to receive(:unsent).and_return([invoice1, invoice2])

      Oroshi::MailerJob.perform_now

      assert_received(Oroshi::InvoiceMailer, :invoice_notification).with(@join1.id)
      assert_received(Oroshi::InvoiceMailer, :invoice_notification).with(@join2.id)
    end

    # routing logic tests
    test 'calls send_all_unsent when arguments are nil' do
      allow(Oroshi::Invoice).to receive(:unsent).and_return([])

      Oroshi::MailerJob.perform_now(nil, nil)

      assert_received(Oroshi::Invoice, :unsent)
    end

    test 'calls send_invoices when both arguments provided' do
      Oroshi::MailerJob.perform_now(@invoice.id, @message.id)

      assert_received(Oroshi::Invoice, :find).with(@invoice.id)
      assert_received(Message, :find).with(@message.id)
    end
  end
end
