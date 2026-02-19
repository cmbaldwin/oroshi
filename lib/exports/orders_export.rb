# frozen_string_literal: true

module Exports
  class OrdersExport < BaseExport
    private

    def export_name
      I18n.t("oroshi.exports.types.orders", default: "注文一覧")
    end

    def load_data
      scope = Oroshi::Order.non_template
                           .where(shipping_date: date_range)
                           .includes(:buyer, :product, :shipping_receptacle,
                                     :shipping_organization, :order_categories,
                                     product_variation: :product,
                                     shipping_method: :shipping_organization)
                           .order(:shipping_date, :buyer_id)
      apply_order_filters(scope).to_a
    end

    def columns
      [
        { key: :shipping_date, header: "出荷日", type: :date,
          value: ->(o) { o.shipping_date } },
        { key: :arrival_date, header: "到着日", type: :date,
          value: ->(o) { o.arrival_date } },
        { key: :buyer, header: "買い手", type: :string,
          value: ->(o) { o.buyer.name } },
        { key: :product, header: "商品", type: :string,
          value: ->(o) { o.product.name } },
        { key: :product_variation, header: "バリエーション", type: :string,
          value: ->(o) { o.product_variation.name } },
        { key: :item_quantity, header: "数量", type: :integer,
          value: ->(o) { o.item_quantity } },
        { key: :receptacle_quantity, header: "ケース数", type: :integer,
          value: ->(o) { o.receptacle_quantity } },
        { key: :freight_quantity, header: "フレート数", type: :integer,
          value: ->(o) { o.freight_quantity } },
        { key: :sale_price_per_item, header: "単価", type: :currency,
          value: ->(o) { format_currency(o.sale_price_per_item) } },
        { key: :revenue, header: "売上", type: :currency,
          value: ->(o) { format_currency(o.revenue) } },
        { key: :expenses, header: "経費", type: :currency,
          value: ->(o) { format_currency(o.expenses) } },
        { key: :total, header: "利益", type: :currency,
          value: ->(o) { format_currency(o.total) } },
        { key: :shipping_method, header: "配送方法", type: :string,
          value: ->(o) { o.shipping_method.name } },
        { key: :shipping_organization, header: "配送組織", type: :string,
          value: ->(o) { o.shipping_organization&.name || "" } },
        { key: :categories, header: "カテゴリ", type: :string,
          value: ->(o) { o.order_categories.map(&:name).join(", ") } },
        { key: :status, header: "ステータス", type: :string,
          value: ->(o) { I18n.t("activerecord.enums.oroshi/order.status.#{o.status}", default: o.status) } },
        { key: :note, header: "ノート", type: :string,
          value: ->(o) { o.note || "" } }
      ]
    end

    def summary_rows
      return [] if records.empty?

      total_revenue = records.sum(&:revenue)
      total_expenses = records.sum(&:expenses)
      total_profit = records.sum(&:total)
      total_items = records.sum(&:item_quantity)

      [
        [ "合計", "", "", "", "", total_items, "", "", "",
          format_currency(total_revenue), format_currency(total_expenses),
          format_currency(total_profit), "", "", "", "", "" ]
      ]
    end
  end
end
