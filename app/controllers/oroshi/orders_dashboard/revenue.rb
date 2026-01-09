# frozen_string_literal: true

module Oroshi
  module OrdersDashboard
    module Revenue
  extend ActiveSupport::Concern

  included do
    before_action :set_revenue_vars, only: %i[revenue]
  end

  # GET /oroshi/orders/:date/revenue
  def revenue
    handle_dashboard_response("revenue")
  end

  private

  # Revenue setup
  def set_revenue_vars
    set_revenue_orders
    set_filters
    group_revenue_orders
    @order_categories = Oroshi::OrderCategory.all
    @buyers = @orders.map(&:buyer).uniq
    @buyer_daily_cost_total = @buyers.map(&:daily_cost).sum
    @shipping_methods = @orders.map(&:shipping_method).uniq
    @shipping_method_costs_total = @shipping_methods.map(&:daily_cost).sum
  end

  def set_revenue_orders
    @orders = Oroshi::Order.non_template.where(shipping_date: @date)
                           .includes(:order_categories, :buyer,
                                     product_variation: %i[supply_type_variations product])
  end

  def group_revenue_orders
    @orders = @grouped_orders
    @grouped_orders = @grouped_orders.group_by { |order| order.product_variation.product }
  end
    end
  end
end
