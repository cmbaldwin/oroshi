# frozen_string_literal: true

require "test_helper"

class Exports::ProductionExportTest < ActiveSupport::TestCase
  setup do
    @production_request = create(:oroshi_production_request)
  end

  test "loads production requests" do
    # Use the manufacture_date from the production request's inventory
    date = @production_request.product_inventory.manufacture_date
    export = Exports::ProductionExport.new(date: date.to_s)
    assert export.records.any?
  end

  test "columns include production fields" do
    date = @production_request.product_inventory.manufacture_date
    export = Exports::ProductionExport.new(date: date.to_s)
    csv = export.generate("csv")
    assert csv.include?("製造日")
    assert csv.include?("依頼数量")
    assert csv.include?("完了数量")
    assert csv.include?("残数量")
    assert csv.include?("ステータス")
  end

  test "generates valid JSON" do
    date = @production_request.product_inventory.manufacture_date
    export = Exports::ProductionExport.new(date: date.to_s)
    json = JSON.parse(export.generate("json"))
    assert json["data"].is_a?(Array)
  end
end
