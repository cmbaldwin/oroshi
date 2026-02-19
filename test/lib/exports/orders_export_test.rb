# frozen_string_literal: true

require "test_helper"

class Exports::OrdersExportTest < ActiveSupport::TestCase
  setup do
    @order = create(:oroshi_order, shipping_date: Time.zone.today)
  end

  test "loads orders for given date" do
    export = Exports::OrdersExport.new(date: Time.zone.today.to_s)
    assert_includes export.records, @order
  end

  test "excludes template orders" do
    template_order = create(:oroshi_order, shipping_date: Time.zone.today)
    Oroshi::OrderTemplate.create!(order: template_order)

    export = Exports::OrdersExport.new(date: Time.zone.today.to_s)
    refute_includes export.records, template_order
  end

  test "filters by buyer_ids" do
    other_buyer = create(:oroshi_buyer)
    other_order = create(:oroshi_order, shipping_date: Time.zone.today, buyer: other_buyer)

    export = Exports::OrdersExport.new(
      date: Time.zone.today.to_s,
      buyer_ids: [@order.buyer_id.to_s]
    )
    assert_includes export.records, @order
    refute_includes export.records, other_order
  end

  test "generates CSV with all columns" do
    export = Exports::OrdersExport.new(date: Time.zone.today.to_s)
    csv = export.generate("csv")
    assert csv.include?("出荷日")
    assert csv.include?("買い手")
    assert csv.include?("利益")
    assert csv.include?(@order.buyer.name)
  end

  test "generates JSON with order data" do
    export = Exports::OrdersExport.new(date: Time.zone.today.to_s)
    json = JSON.parse(export.generate("json"))
    assert json["data"].any? { |d| d["buyer"] == @order.buyer.name }
  end

  test "generates XLSX" do
    export = Exports::OrdersExport.new(date: Time.zone.today.to_s)
    xlsx = export.generate("xlsx")
    assert xlsx.start_with?("PK")
  end

  test "supports date range" do
    past_order = create(:oroshi_order, shipping_date: 5.days.ago.to_date)

    export = Exports::OrdersExport.new(
      start_date: 7.days.ago.to_date.to_s,
      end_date: Time.zone.today.to_s
    )
    assert_includes export.records, @order
    assert_includes export.records, past_order
  end

  test "empty data returns headers only in CSV" do
    export = Exports::OrdersExport.new(date: 1.year.from_now.to_date.to_s)
    csv = export.generate("csv")
    lines = csv.delete_prefix(Exports::CsvExport::BOM).lines
    # Only header row (+ possible summary row, but summary_rows returns [] for empty)
    assert_equal 1, lines.size
  end
end
