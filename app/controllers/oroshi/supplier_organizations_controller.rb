# frozen_string_literal: true

class Oroshi::SupplierOrganizationsController < Oroshi::ApplicationController
  before_action :set_supplier_organizations, only: %i[index load]
  before_action :set_supplier_organization, except: %i[new create]

  # GET /oroshi/supplier_organizations
  def index; end

  # GET /oroshi/supplier_organizations/1/load
  def load
    respond_to do |format|
      format.turbo_stream { render turbo_stream: "load" }
      format.html { render partial: "oroshi/supplier_organizations/dashboard/settings" }
    end
  end

  # GET /oroshi/supplier_organizations/new
  def new
    @supplier_organization = Oroshi::SupplierOrganization.new
    @supplier_organization.active = true
    2.times { @supplier_organization.addresses.build }
  end

  # POST /oroshi/supplier_organizations
  def create
    @supplier_organization = Oroshi::SupplierOrganization.new(supplier_organization_params)
    if @supplier_organization.save
      head :ok
    else
      render partial: "supplier_organization_modal_form", status: :unprocessable_entity
    end
  end

  # GET /oroshi/supplier_organizations/1/edit
  def edit; end

  # PATCH/PUT /oroshi/supplier_organizations/1
  def update
    if @supplier_organization.update(supplier_organization_params)
      head :ok if params[:autosave]
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("supplier_organization",
                                                    template: "oroshi/supplier_organizations/edit"),
                 status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_supplier_organizations
    @supplier_organizations = Oroshi::SupplierOrganization.by_supplier_count
    @show_inactive = params[:show_inactive] == "true"
    @supplier_organizations = @supplier_organizations.active unless @show_inactive
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_supplier_organization
    id = params[:id] || params[:supplier_organization_id]
    @supplier_organization = id ? Oroshi::SupplierOrganization.find(id) : @supplier_organizations.first
  end

  # Only allow a list of trusted parameters through.
  def supplier_organization_params
    boolean_param_set
    params.require(:oroshi_supplier_organization)
          .permit(:entity_name, :entity_type, :invoice_name, :honorific_title, :country_id,
                  :subregion_id, :micro_region, :invoice_number, :fax, :email, :active, :free_entry,
                  addresses_attributes: %i[id default active name company country_id subregion_id
                                           postal_code city address1 address2 phone])
  end

  def boolean_param_set
    return unless params[:oroshi_supplier_organization]

    set_supplier_organization_booleans
    set_address_booleans if params[:oroshi_supplier_organization][:addresses_attributes]
  end

  def set_supplier_organization_booleans
    %i[free_entry active].each do |boolean|
      next unless params[:oroshi_supplier_organization][boolean]
      params[:oroshi_supplier_organization][boolean] = !params[:oroshi_supplier_organization][boolean].to_i.zero?
    end
  end

  def set_address_booleans
    params[:oroshi_supplier_organization][:addresses_attributes].each_value do |address|
      address[:default] = !address[:default].to_i.zero? if address[:default]
      address[:active] = !address[:active].to_i.zero? if address[:active]
    end
  end
end
