# frozen_string_literal: true

class Oroshi::SupplyTypeVariationsController < ApplicationController
  before_action :set_supply_type_variation, except: %i[index new create]
  before_action :set_supply_type, only: %i[index new edit]
  before_action :set_supply_types, only: %i[new create edit update]

  # GET /oroshi/supply_type_variations
  def index
    @supply_type_variations = @supply_type.supply_type_variations
    @show_inactive = params[:show_inactive] == "true"
    @supply_type_variations = @supply_type_variations.active unless @show_inactive
  end

  # GET /oroshi/supply_type_variations/1/edit
  def edit; end

  # GET /oroshi/supply_type_variations/new
  def new
    @supply_type_variation = Oroshi::SupplyTypeVariation.new
    @supply_type_variation.active = true
  end

  # POST /oroshi/supply_type_variations
  def create
    @supply_type_variation = Oroshi::SupplyTypeVariation.new(supply_type_variation_params)

    if @supply_type_variation.save
      head :ok
    else
      render partial: "supply_type_variations_modal_form", status: :unprocessable_entity
    end
  end

  # PATCH/PUT /oroshi/supply_type_variations/1
  def update
    if @supply_type_variation.update(supply_type_variation_params)
      head :ok if params[:autosave]
    else
      render "edit", status: :unprocessable_entity
    end
  end

  # PATCH /oroshi/supply_type_variations/update_positions
  def update_positions
    ActiveRecord::Base.transaction do
      params[:new_positions].each do |new_position|
        supply_type_variation = Oroshi::SupplyTypeVariation.find(new_position[:id])
        supply_type_variation.update_column(:position, new_position[:position].to_i)
      end
    end

    # Respond to the AJAX request
    respond_to do |format|
      format.json { render json: { message: "Positions updated successfully" }, status: :ok }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_supply_type_variation
    id = params[:id] || params[:supply_type_variation_id]
    @supply_type_variation = id ? Oroshi::SupplyTypeVariation.find(id) : Oroshi::SupplyTypeVariation.new
  end

  def set_supply_types
    @supply_types = Oroshi::SupplyType.active
  end

  def set_supply_type
    id = params[:supply_type_id]
    @supply_type = id ? Oroshi::SupplyType.find(id) : Oroshi::SupplyType.active.first
  end

  # Only allow a list of trusted parameters through.
  def supply_type_variation_params
    params.require(:oroshi_supply_type_variation)
          .permit(:name, :handle, :default_container_count, :active, :supply_type_id, :position)
  end
end
