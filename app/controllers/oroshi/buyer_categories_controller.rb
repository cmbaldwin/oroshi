# frozen_string_literal: true

class Oroshi::BuyerCategoriesController < Oroshi::ApplicationController
  before_action :set_buyer_category, only: %i[edit update destroy]

  # GET /oroshi/buyer_categories
  def index
    @buyer_categories = Oroshi::BuyerCategory.all
  end

  # GET /oroshi/buyer_categories/new
  def new
    @buyer_category = Oroshi::BuyerCategory.new
  end

  # POST /oroshi/buyer_categories
  def create
    @buyer_category = Oroshi::BuyerCategory.new(buyer_category_params)
    if @buyer_category.save
      head :ok
    else
      render partial: "buyer_categories_modal_form", status: :unprocessable_entity
    end
  end

  # GET /oroshi/buyer_categories/1/edit
  def edit; end

  # PATCH/PUT /oroshi/buyer_categories/1
  def update
    if @buyer_category.update(buyer_category_params)
      head :ok if params[:autosave]
    else
      render "edit", status: :unprocessable_entity
    end
  end

  # DELETE /oroshi/buyer_categories/1
  def destroy
    @buyer_category.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace("buyer_categories",
                   partial: "oroshi/buyer_categories/index",
                   locals: { buyer_categories: Oroshi::BuyerCategory.all })
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_buyer_category
    id = params[:id] || params[:buyer_category_id]
    @buyer_category = id ? Oroshi::BuyerCategory.find(id) : Oroshi::BuyerCategory.new
  end

  # Only allow a list of trusted parameters through.
  def buyer_category_params
    params.require(:oroshi_buyer_category).permit(:name, :symbol, :color)
  end
end
