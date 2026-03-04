# frozen_string_literal: true

module Exports
  class SupplyExport < BaseExport
    private

    def export_name
      I18n.t("oroshi.exports.types.supply", default: "入荷一覧")
    end

    def load_data
      scope = Oroshi::Supply.with_quantity
                            .joins(:supply_date)
                            .where(supply_dates: { date: date_range })
                            .includes(
                              :supply_date,
                              :supply_reception_time,
                              supply_type_variation: :supply_type,
                              supplier: :supplier_organization
                            )
                            .order("oroshi_supply_dates.date ASC, oroshi_supplies.entry_index ASC")
      scope.to_a
    end

    def columns
      [
        { key: :supply_date, header: "入荷日", type: :date,
          value: ->(s) { s.supply_date.date } },
        { key: :supplier_organization, header: "仕入先組織", type: :string,
          value: ->(s) { s.supplier&.supplier_organization&.entity_name || "" } },
        { key: :supplier, header: "仕入先", type: :string,
          value: ->(s) { s.supplier&.company_name || "" } },
        { key: :supply_type, header: "原料種類", type: :string,
          value: ->(s) { s.supply_type_variation&.supply_type&.name || "" } },
        { key: :supply_type_variation, header: "バリエーション", type: :string,
          value: ->(s) { s.supply_type_variation&.name || "" } },
        { key: :quantity, header: "数量", type: :decimal,
          value: ->(s) { s.quantity } },
        { key: :units, header: "単位", type: :string,
          value: ->(s) { s.supply_type_variation&.supply_type&.units || "" } },
        { key: :price, header: "単価", type: :currency,
          value: ->(s) { format_currency(s.price) } },
        { key: :subtotal, header: "金額", type: :currency,
          value: ->(s) { format_currency(s.quantity * s.price) } },
        { key: :reception_time, header: "受入時間", type: :string,
          value: ->(s) { s.supply_reception_time&.time_qualifier || "" } }
      ]
    end

    def summary_rows
      return [] if records.empty?

      total_amount = records.sum { |s| s.quantity * s.price }

      [
        [ "合計", "", "", "", "", "", "", "",
          format_currency(total_amount), "" ]
      ]
    end
  end
end
