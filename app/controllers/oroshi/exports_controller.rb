# frozen_string_literal: true

class Oroshi::ExportsController < Oroshi::ApplicationController
  before_action :authorize_export

  EXPORT_TYPES = {
    "orders" => "Exports::OrdersExport",
    "revenue" => "Exports::RevenueExport",
    "production" => "Exports::ProductionExport",
    "inventory" => "Exports::InventoryExport",
    "supply" => "Exports::SupplyExport",
    "shipping" => "Exports::ShippingExport"
  }.freeze

  VALID_FORMATS = %w[csv xlsx json pdf].freeze

  # POST /oroshi/exports
  def create
    unless EXPORT_TYPES.key?(params[:export_type])
      return head :unprocessable_entity
    end

    unless VALID_FORMATS.include?(params[:format_type])
      return head :unprocessable_entity
    end

    message = create_export_message
    Oroshi::ExportJob.perform_later(
      export_class_name,
      params[:format_type],
      message.id,
      export_options
    )

    head :ok
  end

  private

  def export_class_name
    EXPORT_TYPES.fetch(params[:export_type])
  end

  def export_options
    params.permit(
      :date, :start_date, :end_date,
      :shipping_organization_id, :print_empty_buyers,
      buyer_ids: [], shipping_method_ids: [],
      order_category_ids: [], buyer_category_ids: []
    ).to_h.compact_blank
  end

  def create_export_message
    Message.create!(
      user: current_user.id,
      model: "oroshi_export",
      state: nil,
      message: I18n.t("oroshi.exports.processing"),
      data: {
        export_type: params[:export_type],
        format: params[:format_type],
        expiration: (DateTime.now + 1.day)
      }
    )
  end

  def authorize_export
    authorize :export, :create?
  end
end
