# frozen_string_literal: true

module Exports
  class RevenueExport < BaseExport
    private

    def export_name
      I18n.t("oroshi.exports.types.revenue", default: "売上・利益")
    end

    def load_data
      scope = Oroshi::Order.non_template
                           .where(shipping_date: date_range)
                           .includes(:buyer, :order_categories,
                                     :shipping_method, :shipping_receptacle,
                                     product_variation: [ :product, :supply_type_variations ])
                           .order(:shipping_date, :buyer_id)
      apply_order_filters(scope).to_a
    end

    def columns
      [
        { key: :shipping_date, header: "出荷日", type: :date,
          value: ->(o) { o.shipping_date } },
        { key: :product, header: "商品", type: :string,
          value: ->(o) { o.product.name } },
        { key: :product_variation, header: "バリエーション", type: :string,
          value: ->(o) { o.product_variation.name } },
        { key: :buyer, header: "買い手", type: :string,
          value: ->(o) { o.buyer.name } },
        { key: :item_quantity, header: "数量", type: :integer,
          value: ->(o) { o.item_quantity } },
        { key: :sale_price_per_item, header: "単価", type: :currency,
          value: ->(o) { format_currency(o.sale_price_per_item) } },
        { key: :revenue, header: "売上", type: :currency,
          value: ->(o) { format_currency(o.revenue) } },
        { key: :revenue_minus_handling, header: "手数料後売上", type: :currency,
          value: ->(o) { format_currency(o.revenue_minus_handling) } },
        { key: :materials_cost, header: "材料費", type: :currency,
          value: ->(o) { format_currency(o.materials_cost) } },
        { key: :shipping_cost, header: "配送費", type: :currency,
          value: ->(o) { format_currency(o.shipping_cost) } },
        { key: :adjustment, header: "調整", type: :currency,
          value: ->(o) { format_currency(o.adjustment) } },
        { key: :expenses, header: "経費合計", type: :currency,
          value: ->(o) { format_currency(o.expenses) } },
        { key: :total, header: "利益", type: :currency,
          value: ->(o) { format_currency(o.total) } }
      ]
    end

    def summary_rows
      return [] if records.empty?

      revenue_subtotal = records.sum(&:revenue_minus_handling)
      expenses_subtotal = records.sum(&:expenses)
      buyer_daily_costs = unique_buyers.sum(&:daily_cost)
      shipping_daily_costs = unique_shipping_methods.sum(&:daily_cost)
      net_profit = revenue_subtotal - expenses_subtotal - buyer_daily_costs - shipping_daily_costs

      [
        [ "収入小計", "", "", "", "", "", "", format_currency(revenue_subtotal),
          "", "", "", "", "" ],
        [ "経費小計", "", "", "", "", "", "", "",
          "", "", "", format_currency(expenses_subtotal), "" ],
        [ "買い手日額経費", "", "", "", "", "", "", "",
          "", "", "", format_currency(buyer_daily_costs), "" ],
        [ "配送日額経費", "", "", "", "", "", "", "",
          "", "", "", format_currency(shipping_daily_costs), "" ],
        [ "純利益", "", "", "", "", "", "", "",
          "", "", "", "", format_currency(net_profit) ]
      ]
    end

    def json_summary
      return {} if records.empty?

      revenue_subtotal = records.sum(&:revenue_minus_handling)
      expenses_subtotal = records.sum(&:expenses)
      buyer_daily_costs = unique_buyers.sum(&:daily_cost)
      shipping_daily_costs = unique_shipping_methods.sum(&:daily_cost)

      {
        revenue_subtotal: format_currency(revenue_subtotal),
        expenses_subtotal: format_currency(expenses_subtotal),
        buyer_daily_costs: format_currency(buyer_daily_costs),
        shipping_method_daily_costs: format_currency(shipping_daily_costs),
        net_profit: format_currency(revenue_subtotal - expenses_subtotal - buyer_daily_costs - shipping_daily_costs)
      }
    end

    def add_summary_worksheet(workbook)
      return if records.empty?

      # Group by date for daily summaries
      by_date = records.group_by(&:shipping_date)
      header_style = workbook.styles.add_style(b: true, bg_color: "F0F0F0")
      currency_style = workbook.styles.add_style(format_code: "#,##0")

      workbook.add_worksheet(name: "日別集計") do |sheet|
        sheet.add_row [ "日付", "収入", "経費", "買い手日額", "配送日額", "純利益" ], style: header_style

        by_date.sort.each do |date, orders|
          revenue = orders.sum(&:revenue_minus_handling)
          expenses = orders.sum(&:expenses)
          buyers = orders.map(&:buyer).uniq
          methods = orders.map(&:shipping_method).uniq
          buyer_cost = buyers.sum(&:daily_cost)
          method_cost = methods.sum(&:daily_cost)
          net = revenue - expenses - buyer_cost - method_cost

          sheet.add_row [ date, revenue, expenses, buyer_cost, method_cost, net ],
                        style: [ nil, currency_style, currency_style, currency_style, currency_style, currency_style ]
        end
      end
    end

    def unique_buyers
      @unique_buyers ||= records.map(&:buyer).uniq
    end

    def unique_shipping_methods
      @unique_shipping_methods ||= records.map(&:shipping_method).uniq
    end
  end
end
