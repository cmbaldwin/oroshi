# frozen_string_literal: true

module Oroshi
  module OrdersDashboard
    module Production
      extend ActiveSupport::Concern

      included do
        # Callbacks
        before_action :set_order_product_inventories, only: %i[production_view]
      end

      # GET /oroshi/orders/:date/production
      def production
        handle_dashboard_response('production')
      end

      # GET /oroshi/orders/:date/production_view/:production_view
      def production_view
        production_view = params[:production_view]
        render partial: "oroshi/orders/dashboard/production/#{production_view}"
      end

      private

      def set_order_product_inventories
        query_dates = [@date..(@date + 2.days)]
        @orders = Oroshi::Order.non_template.where(shipping_date: query_dates)
                               .includes(
                                 :product_inventory,
                                 product_variation: %i[supply_type supply_type_variations product]
                               )
        @products = Oroshi::Product.with_product_variations
                                   .by_product_variation_count.includes(
                                     product_variations:
                                    %i[product supply_type supply_type_variations
                                       production_zones default_shipping_receptacle]
                                   )
        @grouped_product_inventories = Oroshi::ProductInventory.by_manufacture_date(query_dates)
                                                               .includes(:product_variation, :production_requests)
                                                               .group_by(&:product_variation)
      end
    end
  end
end
