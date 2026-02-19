# frozen_string_literal: true

class Oroshi::DocumentationController < Oroshi::ApplicationController
  layout "documentation"

  skip_before_action :maybe_authenticate_user, raise: false
  before_action :authenticate_user_for_docs
  before_action :set_locale
  before_action :set_navigation

  SECTIONS = {
    getting_started: %w[first_login navigation onboarding],
    orders: %w[creating_orders order_templates order_lifecycle bundling_orders searching_orders dashboard_tabs],
    supply_chain: %w[supply_intake suppliers supply_types supply_check_sheets],
    production: %w[production_zones production_requests factory_floor],
    shipping: %w[shipping_methods receptacles shipping_dashboard],
    financials: %w[revenue_tracking profit_calculation payment_receipts invoices materials_costs],
    admin: %w[company_setup buyer_management product_management user_management]
  }.freeze

  ALL_SECTIONS = SECTIONS.keys.map(&:to_s).freeze

  # GET /documentation
  def index
  end

  # GET /documentation/:section
  def section
    @section = params[:section]
    return redirect_to documentation_index_path, alert: t("oroshi.documentation.messages.invalid_section") unless ALL_SECTIONS.include?(@section)

    render "oroshi/documentation/#{@section}/index"
  end

  # GET /documentation/:section/:page
  def page
    @section = params[:section]
    @page = params[:page]

    return redirect_to documentation_index_path, alert: t("oroshi.documentation.messages.invalid_section") unless ALL_SECTIONS.include?(@section)

    pages = SECTIONS[@section.to_sym]
    return redirect_to documentation_section_path(@section), alert: t("oroshi.documentation.messages.invalid_page") unless pages&.include?(@page)

    render "oroshi/documentation/#{@section}/#{@page}"
  end

  private

  def authenticate_user_for_docs
    return unless defined?(Devise)
    return if respond_to?(:current_user) && current_user.present?

    if respond_to?(:authenticate_user!, true)
      authenticate_user!
    else
      redirect_to root_path, alert: t("common.messages.sign_in_required")
    end
  end

  def set_locale
    if params[:locale].present? && %w[ja en].include?(params[:locale])
      I18n.locale = params[:locale].to_sym
      session[:docs_locale] = params[:locale]
    elsif session[:docs_locale].present?
      I18n.locale = session[:docs_locale].to_sym
    end
  end

  def set_navigation
    @sections = SECTIONS
    @current_section = params[:section]
    @current_page = params[:page]
  end
end
