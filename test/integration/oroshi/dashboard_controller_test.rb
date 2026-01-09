# frozen_string_literal: true

require "test_helper"

class Oroshi::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # GET #index
  test "GET index returns http success" do
    get oroshi_root_path
    assert_response :success
  end

  # GET #home
  test "GET home returns http success" do
    get oroshi_dashboard_home_path
    assert_response :success
  end

  # GET #suppliers_organizations
  test "GET suppliers_organizations returns http success" do
    get oroshi_dashboard_suppliers_organizations_path
    assert_response :success
  end

  # GET #supply_types
  test "GET supply_types returns http success" do
    get oroshi_dashboard_supply_types_path
    assert_response :success
  end

  # GET #shipping
  test "GET shipping returns http success" do
    get oroshi_dashboard_shipping_path
    assert_response :success
  end

  # GET #materials
  test "GET materials returns http success" do
    get oroshi_dashboard_materials_path
    assert_response :success
  end

  # GET #buyers
  test "GET buyers returns http success" do
    get oroshi_dashboard_buyers_path
    assert_response :success
  end

  # GET #products
  test "GET products returns http success" do
    get oroshi_dashboard_products_path
    assert_response :success
  end

  # GET #stats
  test "GET stats returns http success" do
    get oroshi_dashboard_stats_path
    assert_response :success
  end

  # GET #company
  test "GET company returns http success" do
    get oroshi_dashboard_company_path
    assert_response :success
  end

  # PATCH #company_settings
  test "PATCH company_settings returns http success" do
    params = {
      company_settings: {
        name: "Test Company",
        postal_code: "123-4567",
        address: "Test Address",
        phone: "123-456-7890",
        fax: "123-456-7890",
        mail: "test@company.com",
        web: "www.test.com",
        invoice_number: "T1234567890123"
      }
    }

    post oroshi_dashboard_company_settings_path, params: params
    assert_response :success
  end
end
