# frozen_string_literal: true

module Oroshi
  module OrdersDashboard
    module Shared
  extend ActiveSupport::Concern

  included do
    # Callbacks
    # These need to take place first, so they are in shared which is processed first in the controller
    before_action :set_order, only: %i[show edit update quantity_update price_update destroy]
    # Views which don't require a date
    before_action :set_date, except: %i[search show calendar calendar_orders new_order_from_template
                                        new_template_from_order create edit update quantity_update
                                        price_update destroy destroy_template]
    # Views which require model attributes
    before_action :set_input_vars, only: %i[show new edit create update]
  end

  private

  # Initilization Settings
  def set_order
    @order = Oroshi::Order.find(params[:id] || params[:order_id])
    @order.is_order_template = @order.order_template.present?
  end

  def set_date
    return redirect_to oroshi_orders_path(date: Time.zone.today.to_s) if params[:date].blank?

    @date = Date.parse(params[:date])
  end

  def order_params
    params_with_date
      .require(:oroshi_order)
      .permit(:buyer_id, :product_variation_id, :shipping_receptacle_id, :shipping_method_id,
              :item_quantity, :receptacle_quantity, :freight_quantity, :shipping_cost, :materials_cost,
              :sale_price_per_item, :adjustment, :note, :is_order_template, :shipping_date,
              :arrival_date, :bundled_with_order_id, :bundled_shipping_receptacle,
              :add_buyer_optional_cost, :manufacture_date, :expiration_date,
              :copy_template, order_category_ids: [])
  end

  def params_with_date
    modified_params = params.dup
    %i[shipping_date arrival_date manufacture_date expiration_date].each do |date_param|
      endpoint = modified_params[:oroshi_order]
      endpoint[date_param] = parse_japanese_date(endpoint[date_param])
    end
    modified_params[:oroshi_order][:is_order_template] =
      modified_params[:oroshi_order][:is_order_template].to_i.positive?
    modified_params
  end

  def parse_japanese_date(date_str)
    Date.strptime(date_str, "%Y\u5E74%m\u6708%d\u65E5") if date_str.present?
  end

  # All dashboard views use this method to render the view
  def handle_dashboard_response(view)
    yield if block_given?
    render partial: "oroshi/orders/dashboard/#{view}"
  end

  # Setup for filters on orders and templates pages
  def set_filters
    set_unique_filter_models
    set_filter_params
    dashboard_settings
    filter_buyers if @buyer_ids.present?
    filter_shipping_methods if @shipping_method_ids.present?
    filter_order_categories if @order_category_ids.present?
    filter_buyer_categories if @buyer_category_ids.present?
  end

  def set_unique_filter_models
    @unique_buyers = merge_and_sort_buyers
    @unique_shipping_methods = merge_and_sort_shipping_methods
    @unique_order_categories = Oroshi::OrderCategory.all
    @unique_buyer_categories = Oroshi::BuyerCategory.all
  end

  def merge_and_sort_buyers
    merge_collections(@order_templates, @orders, :buyer)
      .sort_by(&:associated_system_id)
  end

  def merge_and_sort_shipping_methods
    shipping_methods = merge_collections(@order_templates, @orders, :shipping_method)
    shipping_methods = Oroshi::ShippingMethod.includes(:shipping_organization).where(id: shipping_methods.map(&:id))
    shipping_methods.sort_by { |sm| [ sm.shipping_organization.name, sm.name ] }
  end

  def merge_collections(collection1, collection2, attribute)
    (Array(collection1).map(&attribute) + Array(collection2).map(&attribute)).compact.uniq
  end

  def set_filter_params
    @order_categories = Oroshi::OrderCategory.all
    @grouped_orders = @orders
    @grouped_templates = @order_templates if @order_templates.present?
    %i[order_category_ids buyer_ids shipping_method_ids buyer_category_ids].each do |key|
      instance_variable_set("@#{key}", order_filter_params[key]&.reject(&:blank?))
    end
  end

  def filter_buyers
    @grouped_orders = @grouped_orders.where(buyer_id: @buyer_ids) if @grouped_orders.present?
    return unless @order_templates.present?

    @grouped_templates = @grouped_templates.select do |order_template|
      @buyer_ids.include?(order_template.buyer.id.to_s)
    end
  end

  def filter_shipping_methods
    @grouped_orders = @grouped_orders.where(shipping_method_id: @shipping_method_ids) if @grouped_orders.present?
    return unless @order_templates.present?

    @grouped_templates = @grouped_templates.select do |order_template|
      @shipping_method_ids.include?(order_template.shipping_method.id.to_s)
    end
  end

  def filter_order_categories
    if @grouped_orders.present?
      @grouped_orders = @grouped_orders.joins(:order_categories).where(order_categories: { id: @order_category_ids })
    end
    return unless @order_templates.present?

    @grouped_templates = @grouped_templates.select do |order_template|
      order_template.order_categories.any? { |order_category| @order_category_ids.include?(order_category.id.to_s) }
    end
  end

  def filter_buyer_categories
    if @grouped_orders.present?
      @grouped_orders = @grouped_orders = @grouped_orders.joins(buyer: :buyer_categories).where(buyer_categories: { id: @buyer_category_ids })
    end
    return unless @order_templates.present?

    @grouped_templates = @grouped_templates.select do |order_template|
      order_template.buyer_categories.any? { |buyer_category| @buyer_category_ids.include?(buyer_category.id.to_s) }
    end
  end

  def order_filter_params
    params.permit(:commit, :date,
                  :show_order_category_ids, :show_buyer_ids, :show_shipping_method_ids, :show_buyer_category_ids,
                  order_category_ids: [], buyer_category_ids: [], buyer_ids: [], shipping_method_ids: [])
  end

  def dashboard_settings
    new_params = order_dashboard_setting_params
    user = current_user.id.to_s
    record = Setting.find_or_initialize_by(name: "oroshi_orders_dashboard_settings")
    settings = record.settings || {}
    if new_params.present?
      settings[user] = new_params
      record.update(settings: settings)
    end
    @dashboard_settings = new_params.empty? ? (settings[user] || {}) : new_params
    @dashboard_settings ||= {}
  end

  def order_dashboard_setting_params
    { "show_order_category_ids" => params[:show_order_category_ids],
      "show_buyer_ids" => params[:show_buyer_ids],
      "show_shipping_method_ids" => params[:show_shipping_method_ids],
      "show_buyer_category_ids" => params[:show_buyer_category_ids] }.compact
  end

  def set_input_vars
    @buyers = Oroshi::Buyer.active.order_by_associated_system_id.includes(:shipping_methods)
    @shipping_methods = Oroshi::ShippingMethod.active.includes(:buyers)
    @products = Oroshi::Product.by_product_variation_count.includes(:product_variations, :supply_type)
    @ungrouped_product_variations = Oroshi::ProductVariation.active.includes(:product)
    @product_variations = @ungrouped_product_variations.group_by(&:product)
    @shipping_receptacles = Oroshi::ShippingReceptacle.active.order(:name, :handle, :cost)
    @order_categories = Oroshi::OrderCategory.all
    @buyer_categories = Oroshi::BuyerCategory.all
  end
    end
  end
end
