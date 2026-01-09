# frozen_string_literal: true

module Oroshi
  module OrdersDashboard
    module Sales
  extend ActiveSupport::Concern

  included do
    before_action :set_sales_orders, only: %i[sales]
    before_action :set_order_buyers, only: %i[sales price_update]
  end

  # GET /oroshi/orders/:date/sales
  def sales
    handle_dashboard_response("sales")
  end

  # PATCH/PUT /oroshi/orders/1/price_update
  def price_update
    if @order.update(price_update_order_params)
      @orders = Oroshi::Order.non_template.where(shipping_date: @date).includes(:buyer)
      render turbo_stream: [
        turbo_stream.replace("order_sales_form_#{@order.id}",
                             partial: "oroshi/orders/dashboard/sales/order_sales_form",
                             locals: { order: @order }),
        turbo_stream.replace("buyer_sales_nav",
                             partial: "oroshi/orders/dashboard/sales/buyer_sales_nav",
                             locals: { active_buyer: @order.buyer })
      ]
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def buyer_sales
    @buyer = Oroshi::Buyer.find(params[:buyer_id])
    @grouped_orders = @buyer.orders.where(shipping_date: @date).includes(:product_variation).group_by(&:product)
    render turbo_stream: [
      turbo_stream.replace("buyer_order_sales", partial: "oroshi/orders/dashboard/sales/buyer_sales")
    ]
  end

  private

  def set_sales_orders
    @orders = Oroshi::Order.non_template.where(shipping_date: @date)
                           .includes(:order_categories, :buyer, :product,
                                     shipping_method: %i[buyers shipping_organization],
                                     product_variation: %i[supply_type_variations product])
  end

  def set_order_buyers
    @date ||= @order.shipping_date
    buyer_ids = Oroshi::Order.non_template.where(shipping_date: @date).pluck(:buyer_id).uniq
    @buyers = Oroshi::Buyer.active.order_by_associated_system_id.where(id: buyer_ids)
  end

  def price_update_order_params
    params.require("oroshi_order").permit(:sale_price_per_item)
  end
    end
  end
end
