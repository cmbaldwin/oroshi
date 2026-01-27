# frozen_string_literal: true

class Oroshi::OrdersController < Oroshi::ApplicationController
  include Oroshi::OrdersDashboard::Shared
  include Oroshi::OrdersDashboard::Ransack
  include Oroshi::OrdersDashboard::OrderEntry
  include Oroshi::OrdersDashboard::TemplateView
  include Oroshi::OrdersDashboard::SupplyUsage
  include Oroshi::OrdersDashboard::Production
  include Oroshi::OrdersDashboard::Shipping
  include Oroshi::OrdersDashboard::Sales
  include Oroshi::OrdersDashboard::Revenue

  # Authorization callbacks
  before_action :authorize_order, only: %i[show edit update destroy]
  before_action :authorize_order_create, only: %i[new create new_order_from_template destroy_template]
  before_action :authorize_order_index, only: %i[index search calendar calendar_orders]

  # GET /oroshi/orders/:date
  def index; end

  # GET /oroshi/orders/search
  def search
    @q = policy_scope(Oroshi::Order).ransack(params[:q])
    @orders = @q.result(distinct: true).includes(:buyer, :product_variation, :product,
                                                 :shipping_method, :shipping_organization,
                                                 :shipping_receptacle).group_by(&:buyer)
  end

  # GET /oroshi/orders/1
  def show
    show_orders_modal
  end

  # GET /oroshi/orders/calendar
  def calendar
    render turbo_stream: [
      turbo_stream.replace("orders_modal_content",
                           partial: "oroshi/orders/modal/calendar")
    ]
  end

  # GET /oroshi/orders/calendar/orders
  def calendar_orders
    start_date = params[:start] ? Time.zone.parse(params[:start]) : Time.zone.today.beginning_of_month
    end_date = params[:end] ? Time.zone.parse(params[:end]) : Time.zone.today.end_of_month

    query_start = start_date - 7.days
    query_end = end_date + 7.days

    @orders_by_date = Oroshi::Order.non_template.where(shipping_date: query_start..query_end)
                                   .group(:shipping_date)
                                   .count

    @range = Date.parse(params[:start])..Date.parse(params[:end])
    @holidays = japanese_holiday_background_events(@range)

    render "oroshi/orders/modal/calendar/orders"
  end

  # GET /oroshi/orders/new
  def new
    @order = Oroshi::Order.new
    show_orders_modal
  end

  def new_order_from_template
    create_new_order_from_template
    if @order.save
      @order.update(order_categories: @order_template.order_categories)
      respond_to(&:turbo_stream)
    else
      show_orders_modal(status: :unprocessable_entity)
    end
  end

  # GET /oroshi/orders/1/edit
  def edit; end

  # POST /oroshi/orders
  def create
    # Order_category can only be saved if the order already has an ID
    @order = Oroshi::Order.new(order_params_without_order_catergory_ids)
    if @order.save
      @date = @order.shipping_date
      resave_with_order_categories
    else
      set_input_vars
      show_orders_modal(status: :unprocessable_entity)
    end
  end

  # PATCH/PUT /oroshi/orders/1
  def update
    if order_params.delete(:copy_template) == "1"
      new_template_from_order
    elsif @order.update(order_params)
      turbo_stream.replace("oroshi_order_#{@order.id}",
                           partial: "oroshi/orders/order",
                           locals: { order: @order })
    else
      show_orders_modal(status: :unprocessable_entity)
    end
  end

  def new_template_from_order
    order_template = @order.dup
    order_template.assign_attributes(order_params_without_order_catergory_ids) # remove order category ids
    order_template.is_order_template = true # set as template to trigger template creation callback
    order_template.order_template = nil # remove association to original order
    order_template.save # save the template
    resave_with_order_categories if order_template.persisted?
  end

  # DELETE /oroshi/orders/1
  def destroy
    @order_template = @order.associable_template
    @order.stored_associable_template = @order_template
    @order.destroy
  end

  # DELETE /oroshi/orders/template/template_id
  def destroy_template
    order_template = Oroshi::OrderTemplate.find(params[:template_id])
    order_template.destroy
    render turbo_stream: [
      turbo_stream.remove("oroshi_order_template_#{params[:template_id]}")
    ]
  end

  private

  def show_orders_modal(options = {})
    render turbo_stream: [
      turbo_stream.replace("orders_modal_content", partial: "orders_modal_form")
    ], **options
  end

  def order_params_without_order_catergory_ids
    order_params.except(:order_category_ids)
  end

  def resave_with_order_categories
    @order.order_categories = Oroshi::OrderCategory.where(id: order_params[:order_category_ids])
    @order.save
  end

  def new_order_from_template_params
    params.require("oroshi_order").permit(:shipping_date, :item_quantity, :receptacle_quantity, :freight_quantity)
  end

  def create_new_order_from_template
    @order_template = Oroshi::OrderTemplate.find(params[:template_id])
    @order = @order_template.order.dup
    @order.assign_attributes(new_order_from_template_params)
    @order.arrival_date = @order.shipping_date + @order_template.shipping_arrival_difference
    @order.product_inventory = nil # reset product inventory or else manufacure date set through association will fail
    set_production_dates
    reset_switches
  end

  def set_production_dates
    template_order = @order_template.order
    manufacture_date_distance = (template_order.manufacture_date - template_order.shipping_date).to_i
    expiration_date_distance = (template_order.expiration_date - template_order.manufacture_date).to_i
    @order.manufacture_date = @order.shipping_date + manufacture_date_distance
    @order.expiration_date = @order.manufacture_date + expiration_date_distance
  end

  def reset_switches
    # remove the order template association and make sure the order is not saved as a template
    @order.is_order_template = false
    @order.order_template = nil
    # templates cannot be bundled by default
    @order.bundled_with_order_id = nil
    @order.bundled_shipping_receptacle = false
  end

  # Pundit authorization methods
  def authorize_order
    authorize @order
  end

  def authorize_order_create
    authorize Oroshi::Order, :create?
  end

  def authorize_order_index
    authorize Oroshi::Order, :index?
  end
end
