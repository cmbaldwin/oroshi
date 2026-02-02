# frozen_string_literal: true

module Oroshi
  class OnboardingController < Oroshi::ApplicationController
    layout 'onboarding'

    skip_before_action :maybe_authenticate_user, raise: false
    before_action :authenticate_user_for_onboarding
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

    def show; end

    def update
      # Save step-specific data
      save_result = save_step_data

      # Handle deletion - stay on same step
      if save_result == :deleted
        redirect_to oroshi_onboarding_path(@step), notice: t('oroshi.onboarding.messages.deleted')
        return
      end

      unless save_result
        render :show, status: :unprocessable_entity
        return
      end

      # Mark step complete and redirect
      @progress.mark_step_complete!(@step)
      @progress.update!(current_step: next_step)

      if next_step
        redirect_to oroshi_onboarding_path(next_step), notice: t('oroshi.onboarding.messages.step_completed')
      else
        # All steps complete
        @progress.update!(completed_at: Time.current)
        redirect_to oroshi_root_path, notice: t('oroshi.onboarding.messages.complete')
      end
    end

    def skip
      @progress.update!(skipped_at: Time.current)
      redirect_to oroshi_root_path, notice: t('oroshi.onboarding.messages.skipped')
    end

    def resume
      @progress.update!(skipped_at: nil, checklist_dismissed_at: nil)
      redirect_to oroshi_onboarding_index_path, notice: t('oroshi.onboarding.messages.resuming')
    end

    def dismiss_checklist
      @progress.update!(checklist_dismissed_at: Time.current)
      redirect_to oroshi_root_path, notice: t('oroshi.onboarding.messages.checklist_hidden')
    end

    private

    def authenticate_user_for_onboarding
      return unless defined?(Devise)
      return if respond_to?(:current_user) && current_user.present?

      # Devise is available but user is not authenticated
      if respond_to?(:authenticate_user!, true)
        authenticate_user!
      else
        redirect_to root_path, alert: t('oroshi.onboarding.messages.sign_in_required')
      end
    end

    def find_or_create_progress
      @progress = current_user.onboarding_progress || current_user.create_onboarding_progress!
    end

    def set_step
      @step = params[:id]
      return if ALL_STEPS.include?(@step)

      redirect_to oroshi_onboarding_index_path,
                  alert: t('oroshi.onboarding.messages.invalid_step')
    end

    def next_step
      current_index = ALL_STEPS.index(@step)
      ALL_STEPS[current_index + 1] if current_index
    end

    def save_step_data
      case @step
      when 'company_info'
        save_company_info
      when 'supply_reception_time'
        save_supply_reception_time
      when 'supplier_organization'
        save_supplier_organization
      when 'supplier'
        save_supplier
      when 'supply_type'
        save_supply_type
      when 'supply_type_variation'
        save_supply_type_variation
      when 'buyer'
        save_buyer
      when 'product'
        save_product
      when 'product_variation'
        save_product_variation
      when 'shipping_organization'
        save_shipping_organization
      when 'shipping_method'
        save_shipping_method
      when 'shipping_receptacle'
        save_shipping_receptacle
      when 'order_category'
        save_order_category
      else
        true
      end
    end

    def save_company_info
      @validation_errors = []

      if company_settings_params[:name].blank?
        @validation_errors << t('oroshi.onboarding.steps.company_info.validations.company_name_required')
      end

      if company_settings_params[:postal_code].blank?
        @validation_errors << t('oroshi.onboarding.steps.company_info.validations.postal_code_required')
      end

      if company_settings_params[:address].blank?
        @validation_errors << t('oroshi.onboarding.steps.company_info.validations.address_required')
      end

      return false if @validation_errors.any?

      Setting.find_or_initialize_by(name: 'oroshi_company_settings')
             .update(settings: company_settings_params.to_h)
    rescue ActionController::ParameterMissing
      @validation_errors << t('oroshi.onboarding.steps.company_info.validations.required_fields_missing')
      false
    end

    def company_settings_params
      params.require(:company_settings).permit(:name, :postal_code, :address, :phone, :fax, :mail, :web,
                                               :invoice_number)
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
          flash.now[:alert] = org.errors.full_messages.join(', ')
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
          flash.now[:alert] = supplier.errors.full_messages.join(', ')
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
          flash.now[:alert] = supply_type.errors.full_messages.join(', ')
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
          flash.now[:alert] = variation.errors.full_messages.join(', ')
          return false
        end
      end

      Oroshi::SupplyTypeVariation.any?
    end

    def supply_type_variation_params
      params.require(:supply_type_variation).permit(:supply_type_id, :name, :default_container_count, supplier_ids: [])
    end

    def save_buyer
      if params[:delete_buyer_id].present?
        Oroshi::Buyer.find_by(id: params[:delete_buyer_id])&.destroy
        return :deleted
      end

      buyer_params_hash = params[:buyer]
      if buyer_params_hash.present? && buyer_params_hash[:name].present?
        buyer = Oroshi::Buyer.new(buyer_params)
        unless buyer.save
          flash.now[:alert] = buyer.errors.full_messages.join(', ')
          return false
        end
      end

      Oroshi::Buyer.any?
    end

    def buyer_params
      params.require(:buyer).permit(
        :name, :handle, :entity_type, :handling_cost, :daily_cost,
        :optional_cost, :commission_percentage, :color
      )
    end

    def save_product
      if params[:delete_product_id].present?
        Oroshi::Product.find_by(id: params[:delete_product_id])&.destroy
        return :deleted
      end

      product_params_hash = params[:product]
      if product_params_hash.present? && product_params_hash[:name].present?
        product = Oroshi::Product.new(product_params)
        unless product.save
          flash.now[:alert] = product.errors.full_messages.join(', ')
          return false
        end
      end

      Oroshi::Product.any?
    end

    def product_params
      params.require(:product).permit(
        :name, :units, :supply_type_id, :exterior_height, :exterior_width, :exterior_depth
      )
    end

    def save_product_variation
      if params[:delete_product_variation_id].present?
        Oroshi::ProductVariation.find_by(id: params[:delete_product_variation_id])&.destroy
        return :deleted
      end

      pv_params = params[:product_variation]
      if pv_params.present? && pv_params[:name].present?
        variation = Oroshi::ProductVariation.new(product_variation_params)
        unless variation.save
          flash.now[:alert] = variation.errors.full_messages.join(', ')
          return false
        end
      end

      skip_if_dependencies_missing = Oroshi::ShippingReceptacle.none? || Oroshi::ProductionZone.none?
      Oroshi::ProductVariation.any? || skip_if_dependencies_missing
    end

    def product_variation_params
      params.require(:product_variation).permit(
        :product_id, :name, :handle, :primary_content_volume, :default_shipping_receptacle_id,
        :primary_content_country_id, :primary_content_subregion_id, :shelf_life,
        production_zone_ids: [], supply_type_variation_ids: []
      )
    end

    def save_shipping_organization
      if params[:delete_shipping_organization_id].present?
        Oroshi::ShippingOrganization.find_by(id: params[:delete_shipping_organization_id])&.destroy
        return :deleted
      end

      so_params = params[:shipping_organization]
      if so_params.present? && so_params[:name].present?
        org = Oroshi::ShippingOrganization.new(shipping_organization_params)
        unless org.save
          flash.now[:alert] = org.errors.full_messages.join(', ')
          return false
        end
      end

      Oroshi::ShippingOrganization.any?
    end

    def shipping_organization_params
      params.require(:shipping_organization).permit(:name, :handle)
    end

    def save_shipping_method
      if params[:delete_shipping_method_id].present?
        Oroshi::ShippingMethod.find_by(id: params[:delete_shipping_method_id])&.destroy
        return :deleted
      end

      sm_params = params[:shipping_method]
      if sm_params.present? && sm_params[:name].present?
        method = Oroshi::ShippingMethod.new(shipping_method_params)
        unless method.save
          flash.now[:alert] = method.errors.full_messages.join(', ')
          return false
        end
      end

      Oroshi::ShippingMethod.any?
    end

    def shipping_method_params
      params.require(:shipping_method).permit(
        :shipping_organization_id, :name, :handle, :daily_cost,
        :per_shipping_receptacle_cost, :per_freight_unit_cost, buyer_ids: []
      )
    end

    def save_shipping_receptacle
      if params[:delete_shipping_receptacle_id].present?
        Oroshi::ShippingReceptacle.find_by(id: params[:delete_shipping_receptacle_id])&.destroy
        return :deleted
      end

      sr_params = params[:shipping_receptacle]
      if sr_params.present? && sr_params[:name].present?
        receptacle = Oroshi::ShippingReceptacle.new(shipping_receptacle_params)
        unless receptacle.save
          flash.now[:alert] = receptacle.errors.full_messages.join(', ')
          return false
        end
      end

      Oroshi::ShippingReceptacle.any?
    end

    def shipping_receptacle_params
      params.require(:shipping_receptacle).permit(
        :name, :handle, :cost, :default_freight_bundle_quantity,
        :interior_height, :interior_width, :interior_depth,
        :exterior_height, :exterior_width, :exterior_depth
      )
    end

    def save_order_category
      if params[:delete_order_category_id].present?
        Oroshi::OrderCategory.find_by(id: params[:delete_order_category_id])&.destroy
        return :deleted
      end

      oc_params = params[:order_category]
      if oc_params.present? && oc_params[:name].present?
        category = Oroshi::OrderCategory.new(order_category_params)
        unless category.save
          flash.now[:alert] = category.errors.full_messages.join(', ')
          return false
        end
      end

      Oroshi::OrderCategory.any?
    end

    def order_category_params
      params.require(:order_category).permit(:name, :color)
    end
  end
end
