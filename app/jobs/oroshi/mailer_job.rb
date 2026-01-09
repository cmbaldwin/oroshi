# frozen_string_literal: true

module Oroshi
  class MailerJob < ApplicationJob
    queue_as :default

    def perform(invoice_id = nil, message_id = nil)
      if invoice_id.nil? || message_id.nil?
        send_all_unsent
      else
        invoice = Oroshi::Invoice.find(invoice_id)
        message = Message.find(message_id)
        send_invoices(invoice, message)
      end
    end

    private

    def send_all_unsent
      Oroshi::Invoice.unsent.each do |invoice|
        send_invoices(invoice)
      end
    end

    def send_invoices(invoice, message = nil)
      if send_invoice_notifications(invoice)
        invoice.sent_at = Time.zone.now
        invoice.save
        message&.state = true
        message&.message = "\u30E1\u30FC\u30EB\u3092\u9001\u4FE1\u3057\u307E\u3057\u305F\u3002"
      else
        message&.state = false
        message&.message = "\u30E1\u30FC\u30EB\u306E\u9001\u4FE1\u306B\u5931\u6557\u3057\u307E\u3057\u305F\u3002"
      end
      message&.save
    end

    def send_invoice_notifications(invoice)
      invoice.invoice_supplier_organizations.each do |invoice_supplier_organization|
        next if send_invoice_notification(invoice_supplier_organization)

        Rails.logger.error("Failed to send email for invoice: #{invoice.id}")
        Rails.logger.error(invoice.errors.full_messages)
        return false
      end
    end

    def send_invoice_notification(invoice_supplier_organization)
      unless invoice_supplier_organization.completed
        Rails.logger.error(
          "Error trying to send an incomplete invoice_supplier_organization: #{invoice_supplier_organization.id}"
        )
        return false
      end

      id = invoice_supplier_organization.id
      supplier_email = invoice_supplier_organization.supplier_organization.email

      # Log when sending to company instead of supplier (no supplier email)
      if supplier_email.blank?
        Rails.logger.info(
          "Sending invoice_supplier_organization #{id} to company email: " \
          "supplier organization '#{invoice_supplier_organization.supplier_organization.entity_name}' has no email"
        )
      end

      mail = Oroshi::InvoiceMailer.invoice_notification(id)
      if mail.deliver_now
        invoice_supplier_organization.sent_at = Time.zone.now
        invoice_supplier_organization.completed = true
        invoice_supplier_organization.save
      else
        Rails.logger.error("Failed to send email for invoice_supplier_organization: #{id}")
        Rails.logger.error(mail.errors.full_messages)
        Rails.logger.error(invoice_supplier_organization.errors.full_messages)
        false
      end
    end
  end
end
