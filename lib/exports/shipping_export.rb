# frozen_string_literal: true

module Exports
  class ShippingExport < BaseExport
    # For PDF, delegate to the existing OroshiOrderDocument which has the
    # established B4 landscape layout for shipping charts.
    def generate_pdf
      if options[:shipping_organization_id].present?
        pdf = OroshiOrderDocument.new(
          date_range.first.to_s,
          "shipping_chart",
          options[:shipping_organization_id],
          options[:print_empty_buyers] || "0",
          filter_options
        )
        pdf.render
      else
        super
      end
    end

    private

    def export_name
      I18n.t("oroshi.exports.types.shipping", default: "出荷表")
    end

    def load_data
      scope = Oroshi::Order.non_template
                           .where(shipping_date: date_range)
                           .includes(:buyer, :product, :shipping_receptacle,
                                     :shipping_organization,
                                     product_variation: :product,
                                     shipping_method: :shipping_organization)
                           .order(:shipping_date, :buyer_id)
      apply_order_filters(scope).to_a
    end

    def columns
      [
        { key: :shipping_date, header: "出荷日", type: :date,
          value: ->(o) { o.shipping_date } },
        { key: :shipping_organization, header: "配送組織", type: :string,
          value: ->(o) { o.shipping_organization&.name || "" } },
        { key: :shipping_method, header: "配送方法", type: :string,
          value: ->(o) { o.shipping_method.name } },
        { key: :buyer, header: "買い手", type: :string,
          value: ->(o) { o.buyer.name } },
        { key: :buyer_handle, header: "買い手コード", type: :string,
          value: ->(o) { o.buyer.handle } },
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
        { key: :receptacle, header: "容器", type: :string,
          value: ->(o) { o.shipping_receptacle.name } },
        { key: :note, header: "ノート", type: :string,
          value: ->(o) { o.note || "" } }
      ]
    end

    def summary_rows
      return [] if records.empty?

      total_items = records.sum(&:item_quantity)
      total_receptacles = records.sum(&:receptacle_quantity)
      total_freight = records.sum(&:freight_quantity)

      [
        [ "合計", "", "", "", "", "", "", total_items,
          total_receptacles, total_freight, "", "" ]
      ]
    end

    def filter_options
      {
        "buyer_ids" => options[:buyer_ids],
        "shipping_method_ids" => options[:shipping_method_ids],
        "order_category_ids" => options[:order_category_ids],
        "buyer_category_ids" => options[:buyer_category_ids]
      }.compact
    end
  end
end
