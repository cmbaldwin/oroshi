# frozen_string_literal: true

class Oroshi::SuppliersController < Oroshi::ApplicationController
  before_action :set_supplier
  before_action :set_supplier_organization, only: %i[index new]
  before_action :set_supplier_organizations, only: %i[new update create]

  # Authorization callbacks
  before_action :authorize_supplier_index, only: %i[index]
  before_action :authorize_supplier, only: %i[edit update]
  before_action :authorize_supplier_create, only: %i[new create]

  # GET /oroshi/suppliers
  def index
    @suppliers = policy_scope(Oroshi::Supplier)
    @suppliers = @suppliers.where(supplier_organization: @supplier_organization) if @supplier_organization
    @show_inactive = params[:show_inactive] == "true"
    @suppliers = @suppliers.active unless @show_inactive
    @suppliers = @suppliers&.sort_by(&:supplier_number)
  end

  # GET /oroshi/suppliers/1/edit
  def edit
    @supplier_organizations = Oroshi::SupplierOrganization.active
  end

  # GET /oroshi/suppliers/new
  def new
    @supplier.active = true
    2.times { @supplier.addresses.build }
  end

  # POST /oroshi/suppliers
  def create
    @supplier = Oroshi::Supplier.new(supplier_params)
    if @supplier.save
      head :ok
    else
      render partial: "supplier_modal_form", status: :unprocessable_entity
    end
  end

  # PATCH/PUT /oroshi/suppliers/1
  def update
    if @supplier.update(supplier_params)
      head :ok if params[:autosave]
    else
      render "edit", status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_supplier
    id = params[:id] || params[:supplier_id]
    @supplier = id ? Oroshi::Supplier.find(id) : Oroshi::Supplier.new
  end

  def set_supplier_organization
    id = params[:supplier_organization_id]
    @supplier_organization = id ? Oroshi::SupplierOrganization.find(id) : Oroshi::SupplierOrganization.active.first
  end

  def set_supplier_organizations
    @supplier_organizations = Oroshi::SupplierOrganization.active
  end

  # Only allow a list of trusted parameters through.
  def supplier_params
    params.require(:oroshi_supplier)
          .permit(:company_name, :supplier_number, :user_id, :location,
                  :invoice_number, :invoice_name, :honorific_title,
                  :active, :short_name, :supplier_organization_id,
                  { representatives: [] },
                  supply_type_variation_ids: [],
                  addresses_attributes: %i[id default active name company country_id phone
                                           subregion_id postal_code city address1 address2])
  end

  # Pundit authorization methods
  def authorize_supplier
    authorize @supplier
  end

  def authorize_supplier_create
    authorize Oroshi::Supplier, :create?
  end

  def authorize_supplier_index
    authorize Oroshi::Supplier, :index?
  end
end
