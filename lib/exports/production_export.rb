# frozen_string_literal: true

module Exports
  class ProductionExport < BaseExport
    private

    def export_name
      I18n.t("oroshi.exports.types.production", default: "製造・工場")
    end

    def load_data
      # Match the production dashboard: query ±1 day buffer
      expanded_range = (date_range.first - 1.day)..(date_range.last + 1.day)

      Oroshi::ProductionRequest
        .joins(:product_inventory)
        .where(product_inventories: { manufacture_date: expanded_range })
        .includes(
          :production_zone, :shipping_receptacle,
          product_variation: [ :product, :supply_type, :supply_type_variations ],
          product_inventory: :orders
        )
        .order("oroshi_product_inventories.manufacture_date ASC")
        .to_a
    end

    def columns
      [
        { key: :manufacture_date, header: "製造日", type: :date,
          value: ->(pr) { pr.product_inventory.manufacture_date } },
        { key: :expiration_date, header: "賞味期限", type: :date,
          value: ->(pr) { pr.product_inventory.expiration_date } },
        { key: :product, header: "商品", type: :string,
          value: ->(pr) { pr.product_variation.product.name } },
        { key: :product_variation, header: "バリエーション", type: :string,
          value: ->(pr) { pr.product_variation.name } },
        { key: :production_zone, header: "製造ゾーン", type: :string,
          value: ->(pr) { pr.production_zone&.name || "" } },
        { key: :request_quantity, header: "依頼数量", type: :integer,
          value: ->(pr) { pr.request_quantity } },
        { key: :fulfilled_quantity, header: "完了数量", type: :integer,
          value: ->(pr) { pr.fulfilled_quantity } },
        { key: :remaining, header: "残数量", type: :integer,
          value: ->(pr) { pr.request_quantity - pr.fulfilled_quantity } },
        { key: :inventory_quantity, header: "在庫数量", type: :integer,
          value: ->(pr) { pr.product_inventory.quantity } },
        { key: :status, header: "ステータス", type: :string,
          value: ->(pr) { I18n.t("activerecord.enums.oroshi/production_request.status.#{pr.status}", default: pr.status) } }
      ]
    end

    def summary_rows
      return [] if records.empty?

      total_requested = records.sum(&:request_quantity)
      total_fulfilled = records.sum(&:fulfilled_quantity)
      total_remaining = total_requested - total_fulfilled

      [
        [ "合計", "", "", "", "", total_requested, total_fulfilled,
          total_remaining, "", "" ]
      ]
    end
  end
end
