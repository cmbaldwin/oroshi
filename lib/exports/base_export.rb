# frozen_string_literal: true

module Exports
  class BaseExport
    include Exports::CsvExport
    include Exports::XlsxExport
    include Exports::JsonExport
    include Exports::PdfExport

    attr_reader :options, :records

    def initialize(options = {})
      @options = options.with_indifferent_access
      @records = load_data
    end

    def generate(format)
      validate_format!(format)
      send("generate_#{format}")
    end

    def filename(format)
      ext = FORMAT_EXTENSIONS.fetch(format.to_sym)
      "#{export_name}_#{date_label}_#{timestamp}.#{ext}"
    end

    def content_type(format)
      CONTENT_TYPES.fetch(format.to_sym)
    end

    FORMAT_EXTENSIONS = { csv: "csv", xlsx: "xlsx", json: "json", pdf: "pdf" }.freeze
    CONTENT_TYPES = {
      csv: "text/csv; charset=utf-8",
      xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      json: "application/json; charset=utf-8",
      pdf: "application/pdf"
    }.freeze
    SUPPORTED_FORMATS = FORMAT_EXTENSIONS.keys.freeze

    private

    # Subclasses must implement these
    def load_data = raise NotImplementedError, "#{self.class} must implement #load_data"
    def columns = raise NotImplementedError, "#{self.class} must implement #columns"
    def export_name = raise NotImplementedError, "#{self.class} must implement #export_name"

    def validate_format!(format)
      unless SUPPORTED_FORMATS.include?(format.to_sym)
        raise ArgumentError, "Unsupported export format: #{format}. Supported: #{SUPPORTED_FORMATS.join(', ')}"
      end
    end

    def date_range
      if options[:start_date].present? && options[:end_date].present?
        Date.parse(options[:start_date].to_s)..Date.parse(options[:end_date].to_s)
      elsif options[:date].present?
        date = Date.parse(options[:date].to_s)
        date..date
      else
        today = Time.zone.today
        today..today
      end
    end

    def date_label
      range = date_range
      if range.first == range.last
        range.first.to_s
      else
        "#{range.first}_#{range.last}"
      end
    end

    def timestamp
      Time.zone.now.strftime("%Y%m%d%H%M%S")
    end

    # Shared filter logic (mirrors OrdersDashboard::Shared#set_filters)
    def apply_order_filters(scope)
      scope = scope.where(buyer_id: options[:buyer_ids]) if options[:buyer_ids].present?
      scope = scope.where(shipping_method_id: options[:shipping_method_ids]) if options[:shipping_method_ids].present?
      if options[:order_category_ids].present?
        scope = scope.joins(:order_categories)
                     .where(order_categories: { id: options[:order_category_ids] })
      end
      if options[:buyer_category_ids].present?
        scope = scope.joins(buyer: :buyer_categories)
                     .where(buyer_categories: { id: options[:buyer_category_ids] })
      end
      scope
    end

    def format_date(date)
      return "" if date.nil?

      I18n.l(date, format: :short)
    end

    def format_currency(amount)
      return 0 if amount.nil?

      amount.to_i
    end
  end
end
