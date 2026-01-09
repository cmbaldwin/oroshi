# frozen_string_literal: true

class Oroshi::PaymentReceiptsController < ApplicationController
  include Oroshi::PaymentReceiptsDashboard::Ransack

  before_action :filter_payment_receipt_adjustments, only: %i[create update]
  before_action :convert_date_formats, only: %i[create update]
  before_action :set_payment_receipt, only: %i[edit update destroy]

  # GET /oroshi/payment_receipts
  def index
    @payment_receipts = Oroshi::PaymentReceipt.all
  end

  # GET /oroshi/payment_receipts/quick_entry
  def quick_entry
    @unique_buyers_with_outstanding_payments = Oroshi::Buyer.active.joins(:orders)
                                                            .merge(Oroshi::Order.payment_orphans)
                                                            .distinct
    render "oroshi/payment_receipts/dashboard/quick_entry"
  end

  # GET /oroshi/payment_receipts/single_entry
  def single_entry
    @payment_receipt = Oroshi::PaymentReceipt.new
    render "oroshi/payment_receipts/dashboard/single_entry"
  end

  # GET /oroshi/payment_receipts/search
  def search
    @q = Oroshi::PaymentReceipt.ransack(params[:q])
    @payment_receipts = @q.result(distinct: true)
    render "oroshi/payment_receipts/dashboard/search"
  end

  # GET /oroshi/payment_receipts/buyer/:buyer_id
  def buyer_outstanding
    @payment_receipt = Oroshi::PaymentReceipt.new(buyer_id: params[:buyer_id])
    render "oroshi/payment_receipts/dashboard/quick_entry/buyer_outstanding"
  end

  # GET /oroshi/payment_receipts/buyer_outstanding_list
  def buyer_outstanding_list
    @unique_buyers_with_outstanding_payments = Oroshi::Buyer.active.joins(:orders)
                                                            .merge(Oroshi::Order.payment_orphans)
                                                            .distinct
    render "oroshi/payment_receipts/dashboard/quick_entry/buyer_outstanding_list"
  end

  # POST /oroshi/payment_receipts
  def create
    @payment_receipt = Oroshi::PaymentReceipt.new(payment_receipt_params.except(:order_ids))
    @buyer = Oroshi::Buyer.find(payment_receipt_params[:buyer_id]) if payment_receipt_params[:buyer_id].present?
    associate_orders if @payment_receipt.save
    render "oroshi/payment_receipts/dashboard/quick_entry/buyer_outstanding"
  end

  # GET /oroshi/payment_receipts/1/edit
  def edit; end

  # PATCH/PUT /oroshi/payment_receipts/1
  def update
    return unless @payment_receipt.update(payment_receipt_params)

    head :ok
  end

  # DELETE /oroshi/payment_receipts/1
  def destroy
    @payment_receipt.destroy

    respond_to do |format|
      format.html { redirect_to oroshi_root_path }
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace("payment_receipts",
                   partial: "oroshi/payment_receipts/index",
                   locals: { payment_receipts: Oroshi::PaymentReceipt.all })
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_payment_receipt
    id = params[:id] || params[:payment_receipt_id]
    @payment_receipt = id ? Oroshi::PaymentReceipt.find(id) : Oroshi::PaymentReceipt.new
  end

  def filter_payment_receipt_adjustments
    return unless params[:payment_receipt] && params[:payment_receipt][:payment_receipt_adjustments_attributes]

    params[:payment_receipt][:payment_receipt_adjustments_attributes].each do |key, adjustment|
      if adjustment[:amount].to_f == 0.0
        Oroshi::PaymentReceiptAdjustment.find(adjustment[:id])&.destroy if adjustment[:id]
        params[:payment_receipt][:payment_receipt_adjustments_attributes].delete(key)
      end
    end
  end

  def convert_date_formats
    convert_date_format(:deposit_date)
    convert_date_format(:issue_date)
    convert_date_format(:deadline_date)
  end

  def convert_date_format(date_param_key)
    return unless params[:oroshi_payment_receipt][date_param_key].present?

    japanese_date = params[:oroshi_payment_receipt][date_param_key]
    begin
      parsed_date = Date.strptime(japanese_date, "%Y\u5E74%m\u6708%d\u65E5")
      params[:oroshi_payment_receipt][date_param_key] = parsed_date.strftime("%Y-%m-%d")
    rescue ArgumentError
      # Handle invalid date format if necessary
    end
  end

  # Only allow a list of trusted parameters through.
  def payment_receipt_params
    params.require(:oroshi_payment_receipt).permit(
      :buyer_id, :deposit_date, :total, :payment_receipt_adjustment_type_id,
      :deposit_total, :note, :issue_date, :deadline_date,
      order_ids: [],
      payment_receipt_adjustments_attributes: %i[id payment_receipt_adjustment_type_id amount note _destroy]
    ).tap do |whitelisted|
      whitelisted[:order_ids] = whitelisted[:order_ids].reject(&:blank?) if whitelisted[:order_ids]
    end
  end

  def associate_orders
    Oroshi::Order.where(id: payment_receipt_params[:order_ids]).update_all(payment_receipt_id: @payment_receipt.id)
  end
end
