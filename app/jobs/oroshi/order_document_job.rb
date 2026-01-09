# frozen_string_literal: true

module Oroshi
  class OrderDocumentJob < ApplicationJob
    queue_as :default

    def perform(date, document_type, message_id, shipping_organization_id, print_empty_buyers, options = {})
      message = Message.find(message_id)
      pdf = OroshiOrderDocument.new(date, document_type, shipping_organization_id, print_empty_buyers, options)
      message.data[:filename] = filename(document_type, date)
      io = StringIO.new pdf.render
      message.stored_file.attach(io:, content_type: 'application/pdf', filename: message.data[:filename])
      message.update(state: true, message: "\u6CE8\u6587\u66F8\u985E\u4F5C\u6210\u5B8C\u4E86")
      GC.start
    end

    private

    def filename(document_type, date)
      "(#{date}) - #{document_type} [#{DateTime.now.strftime('%Y%m%d%H%M%S')}].pdf".squish
    end
  end
end
