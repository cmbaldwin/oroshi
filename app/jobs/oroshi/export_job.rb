# frozen_string_literal: true

class Oroshi::ExportJob < ApplicationJob
  queue_as :default

  # @param export_class [String] fully qualified class name (e.g., "Exports::OrdersExport")
  # @param format [String] export format ("csv", "xlsx", "json", "pdf")
  # @param message_id [Integer] Message record ID for status tracking
  # @param options [Hash] export options (date, filters, etc.)
  def perform(export_class, format, message_id, options = {})
    message = Message.find(message_id)

    exporter = export_class.constantize.new(options)
    content = exporter.generate(format)

    io = StringIO.new(content)
    message.stored_file.attach(
      io: io,
      content_type: exporter.content_type(format),
      filename: exporter.filename(format)
    )

    message.update(state: true, message: I18n.t("oroshi.exports.completed"))

    # Free memory after PDF generation (matches existing pattern)
    GC.start if format.to_s == "pdf"
  rescue StandardError => e
    message&.update(state: false, message: I18n.t("oroshi.exports.failed", error: e.message))
    raise
  end
end
