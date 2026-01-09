# frozen_string_literal: true

class Oroshi::DashboardController < ApplicationController
  before_action :check_vip
  before_action :set_supplier_organization, only: %i[index home suppliers_organizations]
  before_action :set_supply_type, only: %i[supply_types]
  before_action :set_shipping_organization, only: %i[shipping]
  before_action :set_product, only: %i[products]

  # GET /oroshi/dashboard
  def index; end

  # GET /oroshi/dashboard/home
  def home
    render partial: "oroshi/dashboard/home"
  end

  # GET /oroshi/dashboard/suppliers_organizations
  def suppliers_organizations
    render partial: "oroshi/dashboard/suppliers_organizations"
  end

  # GET /oroshi/dashboard/supply_types
  def supply_types
    render partial: "oroshi/dashboard/supply_types"
  end

  # GET /oroshi/dashboard/shipping
  def shipping
    render partial: "oroshi/dashboard/shipping"
  end

  # GET /oroshi/dashboard/materials
  def materials
    render partial: "oroshi/dashboard/materials"
  end

  # GET /oroshi/dashboard/buyers
  def buyers
    @buyer = Oroshi::Buyer.first || Oroshi::Buyer.new
    render partial: "oroshi/dashboard/buyers"
  end

  # GET /oroshi/dashboard/products
  def products
    render partial: "oroshi/dashboard/products"
  end

  # GET /oroshi/dashboard/stats
  def stats
    render partial: "oroshi/dashboard/home/stats"
  end

  # GET /oroshi/dashboard/company
  def company
    render partial: "oroshi/dashboard/home/company"
  end

  # PATCH /oroshi/dashboard/company_settings
  def company_settings
    if Setting.find_or_initialize_by(name: "oroshi_company_settings")
              .update(settings: company_settings_params)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  # GET /oroshi/dashboard/subregions
  def subregions
    country = Carmen::Country.coded(params[:country_id])
    subregions = country.subregions.map { |s| { name: s.name, code: s.code } }

    render json: { subregions: subregions }
  end

  private

  def set_supplier_organization
    @supplier_organization = if params[:id].present?
                               Oroshi::SupplierOrganization.find(params[:id])
    else
                               Oroshi::SupplierOrganization.active.by_supplier_count.first
    end
  end

  def set_supply_type
    @supply_type = Oroshi::SupplyType.active.first
  end

  def set_shipping_organization
    @shipping_organization = Oroshi::ShippingOrganization.active.first
  end

  def set_product
    @product = Oroshi::Product.active.first
  end

  # NOTE: permit! is used for dynamic company settings with unknown keys.
  # Access restricted to admin users only.
  def company_settings_params
    params.require("company_settings").permit!
  end
end
