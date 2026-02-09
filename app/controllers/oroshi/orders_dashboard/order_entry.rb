# frozen_string_literal: true

module Oroshi
  module OrdersDashboard
    module OrderEntry
  extend ActiveSupport::Concern

  included do
    # Callbacks
    before_action :set_order_entry_vars, only: %i[orders]
  end

  # POST /oroshi/orders/:date/form
  def orders
    handle_dashboard_response("orders") do
      @grouped_orders = (@grouped_orders || []).group_by(&:product)
      @grouped_templates = (@grouped_templates || []).group_by(&:product)
    end
  end

  # PATCH/PUT /oroshi/orders/1/quantity_update
  def quantity_update
    # if any of the item_quantity, receptacle_quantity, or freight_quantity are 0, return json error with message
    render json: { errors: [ "\u6570\u91CF\u306F0\u306B\u3067\u304D\u307E\u305B\u3093" ] }, status: :unprocessable_entity if quantity_to_zero?

    if @order.update(quantity_update_order_params)
      head :ok
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_order_entry_vars
    set_order_entry_orders
    set_order_entry_templates
    remove_used_order_templates
    set_filters
  end

  def set_order_entry_orders
    @orders = Oroshi::Order.non_template.where(shipping_date: @date)
                           .includes(:order_categories, :buyer, :product, :shipping_receptacle,
                                     shipping_method: %i[buyers shipping_organization],
                                     product_variation: %i[supply_type_variations product])
  end

  def set_order_entry_templates
    @order_templates = Oroshi::OrderTemplate.all
                                            .includes(:order, order: %i[order_categories buyer product_variation
                                                                        shipping_receptacle])
  end

  def remove_used_order_templates
    # get a list of all buyer and product variation combinations in @orders
    # remove any combinations that have an order template with the same
    # buyer product variation, and shipping receptacle in the order template's associated orders
    @order_templates = @order_templates.reject do |order_template|
      @orders&.any? do |order|
        order_template.buyer == order.buyer &&
          order_template.product_variation == order.product_variation &&
          order_template.shipping_receptacle == order.shipping_receptacle &&
          order_template.order_categories == order.order_categories
      end
    end
  end

  def quantity_update_order_params
    params.require(:order).permit(:item_quantity, :receptacle_quantity, :freight_quantity)
  end

  def quantity_to_zero?
    quantity_update_order_params.values.map(&:to_i).any?(&:zero?)
  end
    end
  end
end
