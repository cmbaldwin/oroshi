class Oroshi::OnboardingProgress < ApplicationRecord
  belongs_to :user

  # Ensure completed_steps is always an array
  attribute :completed_steps, :jsonb, default: []

  # Check if onboarding is completed
  def completed?
    completed_at.present?
  end

  # Check if onboarding was skipped
  def skipped?
    skipped_at.present?
  end

  # Check if checklist was dismissed
  def checklist_dismissed?
    checklist_dismissed_at.present?
  end

  # Check if a specific step has been completed
  # When skipped, also verify actual data exists for the step
  def step_completed?(step_name)
    if skipped?
      data_exists_for_step?(step_name)
    else
      completed_steps.include?(step_name.to_s)
    end
  end

  # Check if actual data exists for a step (regardless of completed_steps array)
  def data_exists_for_step?(step_name)
    case step_name.to_s
    when "company_info"
      company_settings = Setting.find_by(name: "oroshi_company_settings")
      company_settings.present? && company_settings.settings&.dig("name").present?
    when "supply_reception_time"
      Oroshi::SupplyReceptionTime.any?
    when "supplier_organization"
      Oroshi::SupplierOrganization.any?
    when "supplier"
      Oroshi::Supplier.any?
    when "supply_type"
      Oroshi::SupplyType.any?
    when "supply_type_variation"
      Oroshi::SupplyTypeVariation.any?
    when "buyer"
      Oroshi::Buyer.any?
    when "product"
      Oroshi::Product.any?
    when "product_variation"
      Oroshi::ProductVariation.any?
    when "shipping_organization"
      Oroshi::ShippingOrganization.any?
    when "shipping_method"
      Oroshi::ShippingMethod.any?
    when "shipping_receptacle"
      Oroshi::ShippingReceptacle.any?
    when "order_category"
      Oroshi::OrderCategory.any?
    else
      false
    end
  end

  # Mark a step as complete (only updates completed_steps array)
  def mark_step_complete!(step_name)
    return if completed_steps.include?(step_name.to_s)

    self.completed_steps = completed_steps + [ step_name.to_s ]
    save!
  end
end
