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
end
