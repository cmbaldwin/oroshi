# frozen_string_literal: true

require "test_helper"

class Exports::ShippingExportTest < ActiveSupport::TestCase
  setup do
    @order = create(:oroshi_order, shipping_date: Time.zone.today)
  end

  test "loads orders for shipping export" do
    export = Exports::ShippingExport.new(date: Time.zone.today.to_s)
    assert_includes export.records, @order
  end

  test "columns include shipping-specific fields" do
    export = Exports::ShippingExport.new(date: Time.zone.today.to_s)
    csv = export.generate("csv")
    assert csv.include?("配送組織")
    assert csv.include?("配送方法")
    assert csv.include?("買い手コード")
    assert csv.include?("ケース数")
    assert csv.include?("フレート数")
    assert csv.include?("容器")
  end

  test "filters by buyer_ids" do
    other_buyer = create(:oroshi_buyer)
    other_order = create(:oroshi_order, shipping_date: Time.zone.today, buyer: other_buyer)

    export = Exports::ShippingExport.new(
      date: Time.zone.today.to_s,
      buyer_ids: [@order.buyer_id.to_s]
    )
    assert_includes export.records, @order
    refute_includes export.records, other_order
  end

  test "generates valid CSV" do
    export = Exports::ShippingExport.new(date: Time.zone.today.to_s)
    csv = export.generate("csv")
    assert csv.present?
    assert csv.include?(@order.buyer.name)
  end
end
