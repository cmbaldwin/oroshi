# frozen_string_literal: true

require "test_helper"

class Exports::InventoryExportTest < ActiveSupport::TestCase
  setup do
    @order = create(:oroshi_order, shipping_date: Time.zone.today)
    @inventory = @order.product_inventory
  end

  test "loads inventories with positive quantity" do
    @inventory.update_column(:quantity, 50)
    export = Exports::InventoryExport.new
    assert export.records.any? { |pi| pi.id == @inventory.id }
  end

  test "excludes zero-quantity inventories" do
    @inventory.update_column(:quantity, 0)
    export = Exports::InventoryExport.new
    refute export.records.any? { |pi| pi.id == @inventory.id }
  end

  test "columns include inventory fields" do
    @inventory.update_column(:quantity, 50)
    export = Exports::InventoryExport.new
    csv = export.generate("csv")
    assert csv.include?("在庫数量")
    assert csv.include?("製造日")
    assert csv.include?("賞味期限")
    assert csv.include?("未出荷注文数")
    assert csv.include?("差分")
  end

  test "generates valid XLSX" do
    @inventory.update_column(:quantity, 50)
    export = Exports::InventoryExport.new
    xlsx = export.generate("xlsx")
    assert xlsx.start_with?("PK")
  end
end
