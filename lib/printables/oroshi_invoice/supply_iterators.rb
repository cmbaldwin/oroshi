# frozen_string_literal: true

# Oyster Supply Iterating Module - Mixin for Supplier Invoice PDF generator
module OroshiInvoice
  module SupplyIterators
    private

    def prepare_invoice_rows
      daily_subtotals
      return unless @subtotals.any? && @layout == 2

      @invoice_subtotal = 0
      @invoice_rows = @subtotals.each_with_object([]) do |(date, subtotals), rows|
        subtotals.sort.each do |supply_type_variation, prices|
          prices.sort.each do |price, volume|
            subtotal = price * volume
            @invoice_subtotal += subtotal
            rows << invoice_row(date, supply_type_variation, price, volume, subtotal)
          end
        end
      end
      @tax_subtotal = @invoice_subtotal * 0.08
    end

    def invoice_row(date, supply_type_variation, price, volume, subtotal)
      [l(date, format: :short),
       { content: "#{supply_type_variation}  ※", colspan: 2 },
       { content: "#{volume} #{supply_type_variation.units}", align: :center },
       { content: en_it(price.to_i, unit: ''), align: :center },
       { content: en_it(subtotal), align: :right }]
    end

    def daily_subtotals
      # to produce a hash like this:
      # { date => { supply_type_variation => { price => { volume: float } } } }
      @subtotals = {}
      grouped_supplies.each do |(date, supply_type_variation), supplies|
        supplies.each do |supply|
          price = supply.price
          volume = supply.quantity
          accumulate_subtotals(date, supply_type_variation, price, volume)
          add_total_value(supply_type_variation, price, volume)
        end
      end
      @subtotals = @subtotals.sort.to_h
    end

    def current_supplies
      return supplies unless @current_supplier

      supplies.where(supplier: @current_supplier)
    end

    def grouped_supplies
      sorted_supplies = current_supplies.sort_by do |supply|
        [supply.supply_type_variation.supply_type.position, supply.supply_type_variation.position]
      end

      sorted_supplies.group_by do |supply|
        [supply.supply_date.date, supply.supply_type_variation]
      end
    end

    def accumulate_subtotals(date, supply_type_variation, price, volume)
      @subtotals[date] ||= {}
      @subtotals[date][supply_type_variation] ||= {}
      @subtotals[date][supply_type_variation][price] ||= 0
      @subtotals[date][supply_type_variation][price] += volume
    end

    def add_total_value(supply_type_variation, price, volume)
      @totals ||= {}
      @totals[supply_type_variation] ||= {}
      @totals[supply_type_variation]['volume'] ||= 0
      @totals[supply_type_variation]['invoice'] ||= 0
      @totals[supply_type_variation]['volume'] += volume
      @totals[supply_type_variation]['invoice'] += price * volume
    end
  end
end
