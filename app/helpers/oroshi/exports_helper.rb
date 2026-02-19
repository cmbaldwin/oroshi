# frozen_string_literal: true

module Oroshi
  module ExportsHelper
    FORMAT_ICONS = {
      "csv" => "filetype-csv",
      "xlsx" => "file-earmark-spreadsheet",
      "pdf" => "filetype-pdf",
      "json" => "filetype-json"
    }.freeze

    def export_format_icon(format)
      icon(FORMAT_ICONS.fetch(format, "file-earmark"))
    end
  end
end
