class Oroshi::OnboardingController < ApplicationController
  layout "onboarding"

  before_action :authenticate_user!
  before_action :find_or_create_progress
  before_action :set_step, only: [ :show, :update ]

  # Ordered onboarding steps grouped by phase
  STEPS = {
    foundation: %w[company_info supply_reception_time],
    supply_chain: %w[supplier_organization supplier supply_type supply_type_variation],
    sales: %w[buyer product product_variation],
    shipping: %w[shipping_organization shipping_method shipping_receptacle order_category]
  }.freeze

  ALL_STEPS = STEPS.values.flatten.freeze

  def index
    # Redirect to current incomplete step or first step
    if @progress.current_step.present? && ALL_STEPS.include?(@progress.current_step)
      redirect_to oroshi_onboarding_path(@progress.current_step)
    else
      redirect_to oroshi_onboarding_path(ALL_STEPS.first)
    end
  end

  def show
    # Render the step form
  end

  def update
    # Save step-specific data
    save_result = save_step_data

    # Handle deletion - stay on same step
    if save_result == :deleted
      redirect_to oroshi_onboarding_path(@step), notice: "削除しました"
      return
    end

    unless save_result
      render :show, status: :unprocessable_entity
      return
    end

    # Mark step complete and redirect to next
    @progress.mark_step_complete!(@step)
    @progress.update!(current_step: next_step)

    if next_step
      redirect_to oroshi_onboarding_path(next_step), notice: "Step completed!"
    else
      # All steps complete
      @progress.update!(completed_at: Time.current)
      redirect_to oroshi_root_path, notice: "Onboarding complete!"
    end
  end

  def skip
    @progress.update!(skipped_at: Time.current)
    redirect_to oroshi_root_path, notice: "Onboarding skipped. You can resume anytime."
  end

  def resume
    @progress.update!(skipped_at: nil)
    redirect_to oroshi_onboarding_index_path, notice: "Resuming onboarding..."
  end

  private

  def find_or_create_progress
    @progress = current_user.onboarding_progress || current_user.create_onboarding_progress!
  end

  def set_step
    @step = params[:id]
    redirect_to oroshi_onboarding_index_path, alert: "Invalid step" unless ALL_STEPS.include?(@step)
  end

  def next_step
    current_index = ALL_STEPS.index(@step)
    ALL_STEPS[current_index + 1] if current_index
  end

  def save_step_data
    case @step
    when "company_info"
      save_company_info
    when "supply_reception_time"
      save_supply_reception_time
    when "supplier_organization"
      save_supplier_organization
    when "supplier"
      save_supplier
    when "supply_type"
      save_supply_type
    when "supply_type_variation"
      save_supply_type_variation
    else
      true
    end
  end

  def save_company_info
    return false if company_settings_params[:name].blank?

    Setting.find_or_initialize_by(name: "oroshi_company_settings")
           .update(settings: company_settings_params.to_h)
  end

  def company_settings_params
    params.require(:company_settings).permit(:name, :postal_code, :address, :phone, :fax, :mail, :web, :invoice_number)
  end

  def save_supply_reception_time
    # Handle deletion if requested
    if params[:delete_supply_reception_time_id].present?
      Oroshi::SupplyReceptionTime.find_by(id: params[:delete_supply_reception_time_id])&.destroy
      return :deleted
    end

    # Add new supply reception time if form submitted with data
    srt_params = params[:supply_reception_time]
    if srt_params.present? && srt_params[:time_qualifier].present? && srt_params[:hour].present?
      Oroshi::SupplyReceptionTime.create!(supply_reception_time_params)
    end

    # Validation: at least one must exist to proceed
    Oroshi::SupplyReceptionTime.any?
  end

  def supply_reception_time_params
    params.require(:supply_reception_time).permit(:time_qualifier, :hour)
  end

  def save_supplier_organization
    # Handle deletion if requested
    if params[:delete_supplier_organization_id].present?
      Oroshi::SupplierOrganization.find_by(id: params[:delete_supplier_organization_id])&.destroy
      return :deleted
    end

    # Add new supplier organization if form submitted with data
    org_params = params[:supplier_organization]
    if org_params.present? && org_params[:entity_name].present?
      org = Oroshi::SupplierOrganization.new(supplier_organization_params)
      unless org.save
        flash.now[:alert] = org.errors.full_messages.join(", ")
        return false
      end
    end

    # Validation: at least one must exist to proceed
    Oroshi::SupplierOrganization.any?
  end

  def supplier_organization_params
    params.require(:supplier_organization).permit(
      :entity_name, :entity_type, :country_id, :subregion_id, :micro_region,
      :invoice_number, :fax, :free_entry, supply_reception_time_ids: []
    )
  end

  def save_supplier
    # Handle deletion if requested
    if params[:delete_supplier_id].present?
      Oroshi::Supplier.find_by(id: params[:delete_supplier_id])&.destroy
      return :deleted
    end

    # Add new supplier if form submitted with data
    sup_params = params[:supplier]
    if sup_params.present? && sup_params[:company_name].present?
      supplier = Oroshi::Supplier.new(supplier_params)
      unless supplier.save
        flash.now[:alert] = supplier.errors.full_messages.join(", ")
        return false
      end
    end

    # Validation: at least one must exist to proceed
    Oroshi::Supplier.any?
  end

  def supplier_params
    params.require(:supplier).permit(
      :company_name, :supplier_number, :representatives, :invoice_number,
      :supplier_organization_id, supply_type_variation_ids: []
    )
  end

  def save_supply_type
    if params[:delete_supply_type_id].present?
      Oroshi::SupplyType.find_by(id: params[:delete_supply_type_id])&.destroy
      return :deleted
    end

    st_params = params[:supply_type]
    if st_params.present? && st_params[:name].present?
      supply_type = Oroshi::SupplyType.new(supply_type_params)
      unless supply_type.save
        flash.now[:alert] = supply_type.errors.full_messages.join(", ")
        return false
      end
    end

    Oroshi::SupplyType.any?
  end

  def supply_type_params
    params.require(:supply_type).permit(:name, :units, :handle, :liquid)
  end

  def save_supply_type_variation
    if params[:delete_supply_type_variation_id].present?
      Oroshi::SupplyTypeVariation.find_by(id: params[:delete_supply_type_variation_id])&.destroy
      return :deleted
    end

    stv_params = params[:supply_type_variation]
    if stv_params.present? && stv_params[:name].present?
      variation = Oroshi::SupplyTypeVariation.new(supply_type_variation_params)
      unless variation.save
        flash.now[:alert] = variation.errors.full_messages.join(", ")
        return false
      end
    end

    Oroshi::SupplyTypeVariation.any?
  end

  def supply_type_variation_params
    params.require(:supply_type_variation).permit(:supply_type_id, :name, :default_container_count, supplier_ids: [])
  end
end
