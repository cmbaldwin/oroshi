# frozen_string_literal: true

module Exports
  class InventoryExport < BaseExport
    private

    def export_name
      I18n.t("oroshi.exports.types.inventory", default: "在庫一覧")
    end

    def load_data
      scope = Oroshi::ProductInventory
                .where("quantity > 0")
                .includes(
                  product_variation: :product,
                  orders: :buyer
                )

      # If date is provided, filter by manufacture_date range
      if options[:date].present? || (options[:start_date].present? && options[:end_date].present?)
        scope = scope.where(manufacture_date: date_range)
      end

      scope.order("oroshi_product_inventories.manufacture_date DESC").to_a
    end

    def columns
      [
        { key: :product, header: "商品", type: :string,
          value: ->(pi) { pi.product_variation.product.name } },
        { key: :product_variation, header: "バリエーション", type: :string,
          value: ->(pi) { pi.product_variation.name } },
        { key: :manufacture_date, header: "製造日", type: :date,
          value: ->(pi) { pi.manufacture_date } },
        { key: :expiration_date, header: "賞味期限", type: :date,
          value: ->(pi) { pi.expiration_date } },
        { key: :quantity, header: "在庫数量", type: :integer,
          value: ->(pi) { pi.quantity } },
        { key: :freight_quantity, header: "フレート数", type: :integer,
          value: ->(pi) { safe_freight_quantity(pi) } },
        { key: :pending_orders, header: "未出荷注文数", type: :integer,
          value: ->(pi) { pending_order_quantity(pi) } },
        { key: :difference, header: "差分", type: :integer,
          value: ->(pi) { pi.quantity - pending_order_quantity(pi) } }
      ]
    end

    def summary_rows
      return [] if records.empty?

      total_quantity = records.sum(&:quantity)
      total_pending = records.sum { |pi| pending_order_quantity(pi) }

      [
        [ "合計", "", "", "", total_quantity, "",
          total_pending, total_quantity - total_pending ]
      ]
    end

    def pending_order_quantity(product_inventory)
      product_inventory.orders.reject(&:shipped?).sum(&:item_quantity)
    end

    def safe_freight_quantity(product_inventory)
      product_inventory.freight_quantity
    rescue
      0
    end
  end
end
