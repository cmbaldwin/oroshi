# frozen_string_literal: true

class Oroshi::InvoicePreviewJob < ApplicationJob
  queue_as :default

  def perform(start_date, end_date, supplier_organization, invoice_format, layout, message_id)
    message = Message.find(message_id)
    start_date = Date.parse(start_date) if start_date.is_a?(String)
    end_date = Date.parse(end_date) if end_date.is_a?(String)

    pdf = OroshiInvoice.new(
      start_date,
      end_date,
      supplier_organization: supplier_organization,
      invoice_format: invoice_format,
      layout: layout
    )

    message.data[:filename] = filename(supplier_organization, start_date, end_date, invoice_format)
    io = StringIO.new pdf.render
    message.stored_file.attach(io: io, content_type: "application/pdf", filename: message.data[:filename])
    message.update(state: true, message: "\u4F9B\u7D66\u6599\u4ED5\u5207\u308A\u66F8\u30D7\u30EC\u30D3\u30E5\u30FC\u4F5C\u6210\u5B8C\u4E86")
  end

  private

  def filename(supplier_organization, start_date, end_date, invoice_format)
    entity_name = Oroshi::SupplierOrganization.find(supplier_organization).entity_name
    "#{entity_name} (#{start_date} ~ #{end_date}) - #{invoice_format} [#{DateTime.now.strftime('%Y%m%d%H%M%S')}].pdf".squish
  end
end
