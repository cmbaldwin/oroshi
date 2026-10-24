# frozen_string_literal: true

module Exports
  module JsonExport
    def generate_json
      data = records.map do |record|
        columns.each_with_object({}) do |col, hash|
          hash[col[:key]] = col[:value].call(record)
        end
      end

      result = {
        export_name: export_name,
        exported_at: Time.zone.now.iso8601,
        date_range: { start: date_range.first.to_s, end: date_range.last.to_s },
        filters: options.except(:date, :start_date, :end_date, :format),
        record_count: data.size,
        data: data
      }

      result[:summary] = json_summary if respond_to?(:json_summary, true)

      result.to_json
    end
  end
end
