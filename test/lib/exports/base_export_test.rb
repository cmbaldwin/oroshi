# frozen_string_literal: true

require "test_helper"

class Exports::BaseExportTest < ActiveSupport::TestCase
  # Concrete subclass for testing the abstract base
  class TestExport < Exports::BaseExport
    private

    def export_name = "テスト"

    def load_data
      [
        OpenStruct.new(name: "Item 1", price: 100),
        OpenStruct.new(name: "Item 2", price: 200)
      ]
    end

    def columns
      [
        { key: :name, header: "名前", type: :string, value: ->(r) { r.name } },
        { key: :price, header: "価格", type: :currency, value: ->(r) { r.price } }
      ]
    end
  end

  setup do
    @export = TestExport.new(date: Time.zone.today.to_s)
  end

  test "loads data on initialization" do
    assert_equal 2, @export.records.size
  end

  test "generates CSV with BOM and headers" do
    csv = @export.generate("csv")
    assert csv.start_with?(Exports::CsvExport::BOM)
    lines = csv.delete_prefix(Exports::CsvExport::BOM).lines
    assert_equal "名前,価格\n", lines.first
    assert_equal 3, lines.size # header + 2 data rows
  end

  test "generates JSON with metadata" do
    json = JSON.parse(@export.generate("json"))
    assert_equal "テスト", json["export_name"]
    assert_equal 2, json["record_count"]
    assert_equal 2, json["data"].size
    assert_equal "Item 1", json["data"].first["name"]
    assert json["exported_at"].present?
  end

  test "generates XLSX" do
    xlsx_data = @export.generate("xlsx")
    assert xlsx_data.is_a?(String)
    assert xlsx_data.length > 0
    # XLSX files start with PK (zip format)
    assert_equal "PK", xlsx_data[0..1]
  end

  test "generates PDF" do
    pdf_data = @export.generate("pdf")
    assert pdf_data.is_a?(String)
    assert pdf_data.start_with?("%PDF")
  end

  test "raises on unsupported format" do
    assert_raises(ArgumentError) { @export.generate("xml") }
  end

  test "filename includes export name and format extension" do
    filename = @export.filename("csv")
    assert filename.end_with?(".csv")
    assert filename.include?("テスト")
  end

  test "content_type returns correct MIME types" do
    assert_equal "text/csv; charset=utf-8", @export.content_type("csv")
    assert_equal "application/json; charset=utf-8", @export.content_type("json")
    assert_equal "application/pdf", @export.content_type("pdf")
    assert @export.content_type("xlsx").include?("spreadsheetml")
  end

  test "handles date range options" do
    export = TestExport.new(start_date: "2026-01-01", end_date: "2026-01-31")
    filename = export.filename("csv")
    assert filename.include?("2026-01-01")
    assert filename.include?("2026-01-31")
  end

  test "handles single date option" do
    export = TestExport.new(date: "2026-02-15")
    filename = export.filename("csv")
    assert filename.include?("2026-02-15")
  end

  test "handles empty records gracefully" do
    empty_export = Class.new(Exports::BaseExport) do
      private
      def export_name = "空"
      def load_data = []
      def columns
        [{ key: :name, header: "名前", type: :string, value: ->(r) { r.name } }]
      end
    end.new

    csv = empty_export.generate("csv")
    lines = csv.delete_prefix(Exports::CsvExport::BOM).lines
    assert_equal 1, lines.size # headers only

    json = JSON.parse(empty_export.generate("json"))
    assert_equal 0, json["record_count"]
    assert_empty json["data"]
  end
end
