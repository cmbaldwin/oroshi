# frozen_string_literal: true

class Oroshi::PaymentReceiptAdjustmentTypesController < Oroshi::ApplicationController
  before_action :set_payment_receipt_adjustment_type, only: %i[edit update destroy]

  # GET /oroshi/payment_receipt_adjustment_types
  def index
    @payment_receipt_adjustment_types = Oroshi::PaymentReceiptAdjustmentType.all
  end

  # GET /oroshi/payment_receipt_adjustment_types/new
  def new
    @payment_receipt_adjustment_type = Oroshi::PaymentReceiptAdjustmentType.new
  end

  # POST /oroshi/payment_receipt_adjustment_types
  def create
    @payment_receipt_adjustment_type = Oroshi::PaymentReceiptAdjustmentType.new(payment_receipt_adjustment_type_params)
    if @payment_receipt_adjustment_type.save
      head :ok
    else
      render partial: "payment_receipt_adjustment_types_modal_form", status: :unprocessable_entity
    end
  end

  # GET /oroshi/payment_receipt_adjustment_types/1/edit
  def edit; end

  # PATCH/PUT /oroshi/payment_receipt_adjustment_types/1
  def update
    if @payment_receipt_adjustment_type.update(payment_receipt_adjustment_type_params)
      head :ok if params[:autosave]
    else
      render "edit", status: :unprocessable_entity
    end
  end

  # DELETE /oroshi/payment_receipt_adjustment_types/1
  def destroy
    @payment_receipt_adjustment_type.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace("payment_receipt_adjustment_types",
                   partial: "oroshi/payment_receipt_adjustment_types/index",
                   locals: { payment_receipt_adjustment_types: Oroshi::PaymentReceiptAdjustmentType.all })
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_payment_receipt_adjustment_type
    id = params[:id] || params[:payment_receipt_adjustment_type_id]
    @payment_receipt_adjustment_type = id ? Oroshi::PaymentReceiptAdjustmentType.find(id) : Oroshi::PaymentReceiptAdjustmentType.new
  end

  # Only allow a list of trusted parameters through.
  def payment_receipt_adjustment_type_params
    params.require(:oroshi_payment_receipt_adjustment_type).permit(:name)
  end
end
