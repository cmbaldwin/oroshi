# frozen_string_literal: true

require "csv"

module Exports
  module CsvExport
    # BOM prefix ensures Excel opens UTF-8 CSV with Japanese characters correctly
    BOM = "\xEF\xBB\xBF"

    def generate_csv
      BOM + CSV.generate do |csv|
        csv << columns.map { |c| c[:header] }
        records.each do |record|
          csv << columns.map { |c| c[:value].call(record) }
        end
        append_summary_rows(csv) if respond_to?(:summary_rows, true)
      end
    end
  end
end
