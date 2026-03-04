# frozen_string_literal: true

require "test_helper"

class Exports::SupplyExportTest < ActiveSupport::TestCase
  setup do
    @supply = create(:oroshi_supply, quantity: 10, price: 500)
    @date = @supply.supply_date.date
  end

  test "loads supplies with quantity for given date" do
    export = Exports::SupplyExport.new(date: @date.to_s)
    assert export.records.any? { |s| s.id == @supply.id }
  end

  test "excludes zero-quantity supplies" do
    zero_supply = create(:oroshi_supply, quantity: 0, price: 0, supply_date: @supply.supply_date)
    export = Exports::SupplyExport.new(date: @date.to_s)
    refute export.records.any? { |s| s.id == zero_supply.id }
  end

  test "columns include supply fields" do
    export = Exports::SupplyExport.new(date: @date.to_s)
    csv = export.generate("csv")
    assert csv.include?("入荷日")
    assert csv.include?("仕入先組織")
    assert csv.include?("数量")
    assert csv.include?("単価")
    assert csv.include?("金額")
  end

  test "supports date range" do
    export = Exports::SupplyExport.new(
      start_date: (@date - 1.day).to_s,
      end_date: (@date + 1.day).to_s
    )
    assert export.records.any? { |s| s.id == @supply.id }
  end
end
