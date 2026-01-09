# frozen_string_literal: true

module Oroshi
  class SupplyDatesController < ApplicationController
    include SupplyPriceAssignment

    before_action :set_supply_dates
    before_action :set_supplier_organizations
    before_action :set_entry_vars, only: %i[entry]
    before_action :set_message, only: %i[checklist]

    # GET /oroshi/supply_dates/:date
    def show; end

    # GET /oroshi/supply_dates/:date/entry/:supplier_organization_id/:supply_reception_time_id
    def entry; end

    # GET /oroshi/supply_dates/:date/checklist/:region_id/:supply_reception_time_ids
    def checklist
      Oroshi::SupplyCheckJob.perform_later(params[:date], @message.id,
                                           [params[:subregion_ids]], params[:supply_reception_time_ids])
      head :ok
    end

    def supply_price_actions
      render_modal('oroshi/supplies/modal/supply_price_actions')
    end

    def supply_invoice_actions
      @invoice = Oroshi::Invoice.new(
        start_date: @dates.first, end_date: @dates.last, supply_dates: @supply_dates, send_email: true
      )
      render_modal('oroshi/supplies/modal/supply_invoice_actions')
    end

    def set_supply_prices
      process_price_assignments
      render_modal('oroshi/supplies/modal/supply_price_results')
    end

    private

    # Only allow a list of trusted parameters through.

    def entry_params
      params.permit(:date, :supplier_organization_id, :supply_reception_time_id)
    end

    def supply_date_params
      params.require(:oroshi_supply_date)
            .permit(:date)
    end

    # NOTE: permit! is used for dynamic supply prices with varying product IDs.
    # Prices are validated by Oroshi::Supply model before saving.
    # Access restricted to authenticated users with proper authorization.
    def supply_prices_params
      params.permit!
    end

    # Use callbacks to share common setup or constraints between actions.

    def set_supply_dates
      date = params[:date]
      @dates = params[:supply_dates]
      if date
        @supply_date = Oroshi::SupplyDate.find_or_create_by(date: params[:date])
      elsif @dates
        @supply_dates = Oroshi::SupplyDate.where(date: @dates).order(:date)
        @supplier_organizations = @supply_dates.map(&:supplier_organizations).flatten.uniq
      end
    end

    def set_supplier_organizations
      @supplier_organizations = Oroshi::SupplierOrganization.active.by_subregion.by_supplier_count
                                                            .includes(:supply_reception_times)
    end

    # Supply Entry Page Setup
    def set_entry_vars
      @supplier_organization = Oroshi::SupplierOrganization.includes(suppliers: [supply_type_variations: :supply_type])
                                                           .find(params[:supplier_organization_id])
      @supply_reception_time = Oroshi::SupplyReceptionTime.find(params[:supply_reception_time_id])
      @supply_type_variations = @supplier_organization.suppliers.map(&:supply_type_variations).flatten.uniq
      @supplies = Oroshi::Supply
                  .includes(:supplier, :supply_type_variation, :supply_date, :supply_reception_time)
                  .where(supply_date: @supply_date, supply_reception_time: @supply_reception_time,
                         supplier: @supplier_organization.suppliers)
    end

    def set_message
      @filename = "供給チェック表 #{params.values[2..].join}.pdf"
      @message = Message.new(
        user: current_user.id,
        model: 'supply_check',
        state: false,
        message: "#{params[:date]}供給受入れチェック表を作成中…",
        data: {
          supply_date: params[:date],
          filename: @filename,
          expiration: (DateTime.now + 1.day)
        }
      )
      @message.save
    end

    def render_modal(path)
      respond_to do |format|
        format.turbo_stream do
          render 'oroshi/supplies/modal/replace_supply_modal', locals: { path: path }
        end
        format.html { render path }
      end
    end
  end
end
