# frozen_string_literal: true

require "caxlsx"

module Exports
  module XlsxExport
    def generate_xlsx
      package = Axlsx::Package.new
      workbook = package.workbook

      header_style = workbook.styles.add_style(b: true, bg_color: "F0F0F0", border: Axlsx::STYLE_THIN_BORDER)
      currency_style = workbook.styles.add_style(format_code: '#,##0', border: Axlsx::STYLE_THIN_BORDER)
      date_style = workbook.styles.add_style(format_code: "yyyy/mm/dd", border: Axlsx::STYLE_THIN_BORDER)
      default_style = workbook.styles.add_style(border: Axlsx::STYLE_THIN_BORDER)

      workbook.add_worksheet(name: export_name.truncate(31)) do |sheet|
        sheet.add_row columns.map { |c| c[:header] }, style: header_style

        records.each do |record|
          values = columns.map { |c| c[:value].call(record) }
          styles = columns.map do |c|
            case c[:type]
            when :currency then currency_style
            when :date then date_style
            else default_style
            end
          end
          sheet.add_row values, style: styles
        end

        if respond_to?(:summary_rows, true)
          summary_style = workbook.styles.add_style(b: true, bg_color: "FFFFCC", border: Axlsx::STYLE_THIN_BORDER)
          summary_rows.each do |row|
            sheet.add_row row, style: summary_style
          end
        end
      end

      # Add summary worksheet if available
      add_summary_worksheet(workbook) if respond_to?(:add_summary_worksheet, true)

      stream = package.to_stream
      stream.read
    end
  end
end
