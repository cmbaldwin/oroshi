# frozen_string_literal: true

module Oroshi
  module OrdersDashboard
    module SupplyUsage
      extend ActiveSupport::Concern

      included do
        before_action :set_supply_volumes, only: %i[supply_volumes]
        before_action :set_product_inventories, only: %i[product_inventories]
      end

      # GET /oroshi/orders/:date/supply_usage
      def supply_usage
        handle_dashboard_response('supply_usage')
      end

      # GET /oroshi/orders/:date/supply_volumes
      def supply_volumes
        render turbo_stream: [
          turbo_stream.replace('supply_volumes', partial: 'oroshi/orders/dashboard/orders/supply_volumes')
        ]
      end

      # GET /oroshi/orders/:date/product_inventories
      def product_inventories
        render turbo_stream: [
          turbo_stream.replace('product_inventories', partial: 'oroshi/orders/dashboard/orders/product_inventories')
        ]
      end

      private

      def set_supply_volumes
        @orders = Oroshi::Order.non_template.where(shipping_date: @date)
                               .includes(product_variation: [
                                           { product: :supply_type },
                                           { supply_type_variations: :supply_type }
                                         ])
        @supply_volumes = calculate_supply_volumes
      end

      def calculate_supply_volumes
        @orders.each_with_object({}) do |order, hash|
          volume = calculate_volume(order)
          product_variation = order.product_variation
          product = product_variation.product
          region_name = product_variation.region.name

          hash[region_name] ||= {}
          hash[region_name][product] ||= { total: 0, units: product.supply_type.units }

          add_volume_to_hash(hash, region_name, product, product_variation, volume)
        end
      end

      def calculate_volume(order)
        order.product_variation.primary_content_volume * order.item_quantity
      end

      def add_volume_to_hash(hash, region_name, product, product_variation, volume)
        hash[region_name][product][:total] += volume
        hash[region_name][product][product_variation] ||= 0
        hash[region_name][product][product_variation] += volume
      end

      def set_product_inventories
        @orders = Oroshi::Order.non_template.where(shipping_date: @date)
                               .includes(:product_inventory, product_variation: [:product])
        @product_inventories = @orders.each_with_object({}) do |order, hash|
          product_variation = order.product_variation
          product = product_variation.product

          hash[product] ||= {}
          hash[product][product_variation] ||= [0, 0]
          hash[product][product_variation][0] += order.item_quantity
          hash[product][product_variation][1] += order.product_inventory.quantity
        end
      end
    end
  end
end
