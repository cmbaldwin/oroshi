# frozen_string_literal: true

module Oroshi
  module PaymentReceiptsDashboard
    module Ransack
  extend ActiveSupport::Concern

  included do
    before_action :convert_date_params, only: %i[search]
    before_action :init_ransack_params, only: %i[search]
  end

  private

  def init_ransack_params
    params[:q] ||= {}
    json_today = Time.zone.today.to_json
    params[:q][:deposit_date_gteq] ||= json_today
    params[:q][:deposit_date_lteq] ||= json_today
    form_select_options
  end

  def form_select_options
    @buyers = Oroshi::Buyer.active.order_by_associated_system_id
    @buyer_categories = Oroshi::BuyerCategory.all
  end

  def convert_date_params
    return unless params[:q]

    %i[deposit_date_gteq deposit_date_lteq].each do |date_param|
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
