# frozen_string_literal: true

# Restaurant Order Packing Lists PDF Generator
class OroshiOrderDocument < Printable
  include ActionView::Helpers::TranslationHelper

  # @param [Date] date
  # @param [String] document_type -> 'shipping_chart' or 'shipping_list' for now
  # @param [Hash] options
  def initialize(date, document_type, shipping_organization_id, print_empty_buyers, options = {})
    @document_type = document_type
    @options = options
    super(page_size: page_size, page_layout: page_layout, margin: margin)
    @date = Time.zone.parse(date).to_date
    init_vars(shipping_organization_id, print_empty_buyers)
    send("generate_#{document_type}_order_document")
  end

  private

  def page_size
    case @document_type
    when 'shipping_chart' || 'shipping_list' then 'B4'
    else 'A4'
    end
  end

  def margin
    case @document_type
    when 'shipping_chart' || 'shipping_list' then [15, 15, 15, 15]
    else [15, 15, 30, 15]
    end
  end

  def page_layout
    case @document_type
    when 'shipping_list'
      :landscape
    else
      :portrait
    end
  end

  def init_vars(shipping_organization_id, print_empty_buyers)
    filter_orders
    group_by_shipping_organization(shipping_organization_id)
    @buyers = if print_empty_buyers == '0'
                @shipping_organization.buyers.uniq.sort_by(&:associated_system_id)
              elsif print_empty_buyers.to_i.positive?
                Oroshi::Buyer.joins(:buyer_categories).where(buyer_categories: { id: print_empty_buyers })
                             .sort_by(&:associated_system_id)
              else
                @orders.map(&:buyer).uniq.sort_by(&:associated_system_id)
              end
    @products = Oroshi::Product.all.includes(%i[product_variations supply_type])
  end

  def filter_orders
    conditions = { shipping_date: @date }
    conditions[:buyer_id] = @options['buyer_ids'] if @options['buyer_ids'].present?
    conditions[:shipping_method_id] = @options['shipping_method_ids'] if @options['shipping_method_ids'].present?

    @orders = Oroshi::Order.non_template.includes(:buyer, :product, :shipping_organization)

    if @options['order_category_ids'].present?
      @orders = @orders.joins(:order_order_categories)
                       .where(order_order_categories: { order_category_id: @options['order_category_ids'] })
    end

    @orders = @orders.where(conditions)
  end

  def group_by_shipping_organization(shipping_organization_id)
    return unless shipping_organization_id

    @shipping_organization = Oroshi::ShippingOrganization.find(shipping_organization_id)
    @orders = @orders.group_by(&:shipping_organization)[@shipping_organization] if @shipping_organization
  end

  def generate_shipping_chart_order_document
    print_title
    table(table_data, header: true, width: bounds.width, column_widths: { 0 => 5 }) do
      row(0).font_style = :bold
      row(0).align = :center
      row(0).background_color = 'f0f0f0'
      cells.border_width = 0.5
    end
  end

  def table_data
    [header_row, *order_rows, product_totals_row]
  end

  def print_title
    title = "#{@shipping_organization.name} #{I18n.l(@date, format: :short)} 出荷表"

    if @options.present?
      option_details = []
      if @options['order_category_ids'].present?
        option_details << "#{Oroshi::OrderCategory.model_name.human}:#{fetch_order_category_names}"
      end
      option_details << "#{Oroshi::Buyer.model_name.human}:#{fetch_buyer_names}" if @options['buyer_ids'].present?
      if @options['shipping_method_ids'].present?
        option_details << "#{Oroshi::ShippingMethod.model_name.human}:#{fetch_shipping_method_names}"
      end
      title += " (#{option_details.join(', ')})"
    end

    text title, size: 10, style: :bold
    move_down 5
    font_size 8
  end

  def fetch_order_category_names
    Oroshi::OrderCategory.where(id: @options['order_category_ids']).pluck(:name).join(', ')
  end

  def fetch_buyer_names
    Oroshi::Buyer.where(id: @options['buyer_ids']).pluck(:name).join(', ')
  end

  def fetch_shipping_method_names
    Oroshi::ShippingMethod.where(id: @options['shipping_method_ids']).pluck(:name).join(', ')
  end

  def header_row
    [{ content: Oroshi::Buyer.model_name.human, colspan: 2 }, *@products.map(&:name), "\u5408\u8A08"]
  end

  def order_rows
    initialize_product_totals
    @buyers.map do |buyer|
      @current_buyer = buyer
      @current_orders = @orders.select { |order| order.buyer == buyer }
      order_row
    end
  end

  def initialize_product_totals
    @product_totals = @products.each_with_object({}) do |product, hash|
      hash[product] = 0
    end
  end

  def order_row
    [buyer_color_cell, @current_buyer.handle, *product_columns, total_column]
  end

  def buyer_color_cell
    { content: '', background_color: @current_buyer.color.delete('#') }
  end

  def product_columns
    @products.map do |product|
      orders_by_product = @current_orders.select { |order| order.product == product }
      orders_by_variation = orders_by_product.group_by(&:product_variation)
      @product_totals[product] += orders_by_product.sum(&:freight_quantity)
      orders_by_variation.map do |product_variation, orders|
        "#{orders.sum(&:freight_quantity)} (#{product_variation.handle})"
      end.join("\n")
    end
  end

  def total_column
    @current_orders.sum(&:freight_quantity)
  end

  def product_totals_row
    [{ content: "\u5408\u8A08", colspan: 2 }, *product_total_strings, @product_totals.values.sum]
  end

  def product_total_strings
    @product_totals.values.map { |total| total.zero? ? '' : total }
  end
end
