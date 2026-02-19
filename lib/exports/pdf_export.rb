# frozen_string_literal: true

module Exports
  module PdfExport
    def generate_pdf
      pdf = Printable.new(page_size: pdf_page_size, page_layout: pdf_page_layout)
      pdf.text pdf_title, size: 14, style: :bold
      pdf.move_down 5
      pdf.text pdf_subtitle, size: 8 if respond_to?(:pdf_subtitle, true)
      pdf.move_down 10

      table_data = [ columns.map { |c| c[:header] } ]
      records.each do |record|
        table_data << columns.map { |c| c[:value].call(record).to_s }
      end

      if respond_to?(:summary_rows, true)
        summary_rows.each { |row| table_data << row.map(&:to_s) }
      end

      pdf.font_size 7
      pdf.table(table_data, header: true, width: pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = "f0f0f0"
        cells.border_width = 0.5
        cells.padding = 3
      end

      pdf.render
    end

    private

    def pdf_page_size = "A4"
    def pdf_page_layout = :landscape

    def pdf_title
      "#{export_name} #{date_range.first == date_range.last ? format_date(date_range.first) : "#{format_date(date_range.first)} ~ #{format_date(date_range.last)}"}"
    end
  end
end
