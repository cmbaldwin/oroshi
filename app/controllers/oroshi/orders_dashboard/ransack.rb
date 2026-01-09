# frozen_string_literal: true

module Oroshi
  module OrdersDashboard
    module Ransack
  extend ActiveSupport::Concern

  included do
    before_action :convert_date_params, only: %i[search]
    before_action :init_ransack_params, only: %i[search]
  end

  private

  def init_ransack_params
    params[:q] ||= {}
    params[:q][:shipping_date_gteq] ||= Time.zone.today
    params[:q][:shipping_date_lteq] ||= Time.zone.today
    form_select_options
  end

  def form_select_options
    @buyers = Oroshi::Buyer.active.order_by_associated_system_id
    @shipping_organizations = Oroshi::ShippingOrganization.active.order(:name)
    @shipping_methods = Oroshi::ShippingMethod.active
    @products = Oroshi::Product.by_product_variation_count
    @product_variations = Oroshi::ProductVariation.active
    @shipping_receptacles = Oroshi::ShippingReceptacle.active.order(:name, :handle, :cost)
    @order_categories = Oroshi::OrderCategory.all
    @buyer_categories = Oroshi::BuyerCategory.all
  end

  def convert_date_params
    return unless params[:q]

    %i[shipping_date_gteq shipping_date_lteq].each do |date_param|
      params[:q][date_param] = convert_date(params[:q][date_param]) if params[:q][date_param].present?
    end
  end

  def convert_date(date_str)
    Date.strptime(date_str, "%Y\u5E74%m\u6708%d\u65E5").strftime("%Y-%m-%d")
  rescue ArgumentError
    nil
  end
    end
  end
end
