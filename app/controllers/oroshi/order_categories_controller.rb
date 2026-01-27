# frozen_string_literal: true

class Oroshi::OrderCategoriesController < Oroshi::ApplicationController
  before_action :set_order_category, only: %i[edit update destroy]

  # GET /oroshi/order_categories
  def index
    @order_categories = Oroshi::OrderCategory.all
  end

  # GET /oroshi/order_categories/new
  def new
    @order_category = Oroshi::OrderCategory.new
  end

  # POST /oroshi/order_categories
  def create
    @order_category = Oroshi::OrderCategory.new(order_category_params)
    if @order_category.save
      head :ok
    else
      render partial: "order_categories_modal_form", status: :unprocessable_entity
    end
  end

  # GET /oroshi/order_categories/1/edit
  def edit; end

  # PATCH/PUT /oroshi/order_categories/1
  def update
    if @order_category.update(order_category_params)
      head :ok if params[:autosave]
    else
      render "edit", status: :unprocessable_entity
    end
  end

  # DELETE /oroshi/order_categories/1
  def destroy
    @order_category.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace("order_categories",
                   partial: "oroshi/order_categories/index",
                   locals: { order_categories: Oroshi::OrderCategory.all })
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_order_category
    id = params[:id] || params[:order_category_id]
    @order_category = id ? Oroshi::OrderCategory.find(id) : Oroshi::OrderCategory.new
  end

  # Only allow a list of trusted parameters through.
  def order_category_params
    params.require(:oroshi_order_category).permit(:name, :color)
  end
end
