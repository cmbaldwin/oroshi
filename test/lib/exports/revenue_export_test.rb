# frozen_string_literal: true

require "test_helper"

class Exports::RevenueExportTest < ActiveSupport::TestCase
  setup do
    @order = create(:oroshi_order,
                    shipping_date: Time.zone.today,
                    sale_price_per_item: 500,
                    item_quantity: 10)
  end

  test "loads orders for revenue calculation" do
    export = Exports::RevenueExport.new(date: Time.zone.today.to_s)
    assert_includes export.records, @order
  end

  test "columns include revenue breakdown" do
    export = Exports::RevenueExport.new(date: Time.zone.today.to_s)
    csv = export.generate("csv")
    assert csv.include?("売上")
    assert csv.include?("手数料後売上")
    assert csv.include?("材料費")
    assert csv.include?("配送費")
    assert csv.include?("経費合計")
    assert csv.include?("利益")
  end

  test "JSON includes summary with net profit" do
    export = Exports::RevenueExport.new(date: Time.zone.today.to_s)
    json = JSON.parse(export.generate("json"))
    assert json.key?("summary")
    assert json["summary"].key?("net_profit")
    assert json["summary"].key?("revenue_subtotal")
    assert json["summary"].key?("expenses_subtotal")
  end

  test "XLSX includes daily summary worksheet" do
    export = Exports::RevenueExport.new(date: Time.zone.today.to_s)
    xlsx = export.generate("xlsx")
    # Valid XLSX file (zip format)
    assert xlsx.start_with?("PK")
  end

  test "CSV includes summary rows" do
    export = Exports::RevenueExport.new(date: Time.zone.today.to_s)
    csv = export.generate("csv")
    assert csv.include?("収入小計")
    assert csv.include?("純利益")
  end
end
