# frozen_string_literal: true

module Oroshi
  class InvoiceJob < ApplicationJob
    queue_as :default

    def perform(invoice_id, message_id)
      message = Message.find(message_id)
      invoice = Oroshi::Invoice.find(invoice_id)

      create_or_refresh_invoices(invoice)
      message.update(state: true, message: "\u4F9B\u7D66\u6599\u4ED5\u5207\u308A\u66F8\u4F5C\u6210\u5B8C\u4E86")
    end

    private

    def create_or_refresh_invoices(invoice)
      passwords = {}

      invoice.invoice_supplier_organizations.each do |join|
        reset_join(join)
        %w[organization supplier].each do |invoice_format|
          password = SecureRandom.hex(4)
          invoice_record = join.invoices.attach(
            io: generate_pdf(invoice, join, invoice_format, password),
            content_type: 'application/pdf',
            filename: filename(invoice, join, invoice_format)
          ).last
          invoice_record.save!
          passwords[invoice_record.id] = password
        end
        join.update!(passwords: passwords, completed: true)
        passwords = {}
      end
    end

    def reset_join(join)
      join.transaction do
        join.invoices.purge
        join.update!(passwords: {})
        join.completed = false
      end
    end

    def generate_pdf(invoice, join, invoice_format, password)
      pdf = OroshiInvoice.new(
        invoice.start_date,
        invoice.end_date,
        supplier_organization: join.supplier_organization.id,
        invoice_format: invoice_format,
        layout: invoice.invoice_layout,
        invoice_date: invoice.invoice_date,
        password: password
      )
      StringIO.new pdf.render
    end

    def filename(invoice, join, invoice_format)
      template_name = invoice_format == 'organization' ? "\u7D44\u7E54" : "\u4F9B\u7D66\u8005"
      "#{join.supplier_organization.entity_name} (#{invoice.start_date} ~ #{invoice.end_date}) - #{template_name}.pdf".squish
    end
  end
end
