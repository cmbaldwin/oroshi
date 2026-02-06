# frozen_string_literal: true

require "test_helper"

class Oroshi::SupplyDatesControllerTest < ActionDispatch::IntegrationTest
  include Oroshi::SuppliesHelper

  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # GET #entry
  test "GET entry returns http success" do
    supply_date = create(:oroshi_supply_date)
    supplier_organization = create(:oroshi_supplier_organization)
    supply_reception_time = create(:oroshi_supply_reception_time)
    post entry_oroshi_supply_date_path(supply_date.date, supplier_organization.id, supply_reception_time.id),
         as: :turbo_stream
    assert_response :success
  end

  # GET #checklist
  test "GET checklist returns http success" do
    get checklist_oroshi_supply_date_path("2022-01-01", "1", "1")
    assert_response :success
  end

  # GET #supply_price_actions
  test "GET supply_price_actions returns http success" do
    supply_date = create(:oroshi_supply_date)
    get supply_price_actions_oroshi_supply_dates_path, params: {
      supply_dates: [ supply_date.date ]
    }, as: :turbo_stream
    assert_response :ok
  end

  # GET #supply_invoice_actions
  test "GET supply_invoice_actions returns http success" do
    supply_date = create(:oroshi_supply_date)
    get supply_invoice_actions_oroshi_supply_dates_path, params: {
      supply_dates: [ supply_date.date ]
    }, as: :turbo_stream
    assert_response :ok
  end

  # POST #set_supply_prices
  test "POST set_supply_prices returns http success and sets supply prices" do
    supply_date = create(:oroshi_supply_date, :with_supplies, zero_price: true)
    supply_dates = [ supply_date ]
    set_supply_price_params = build_set_supply_price_params(supply_date, supply_dates)

    assert supply_date.supply.count > 0
    post set_supply_prices_oroshi_supply_dates_path, params: set_supply_price_params, as: :turbo_stream
    assert_response :success
    assert_equal 0, supply_date.incomplete_supply.count
  end

  private

  def build_set_supply_price_params(supply_date, supply_dates)
    {
      "prices" =>
      supply_date.supplier_organizations.each_with_object({}) do |supplier_organization, hash|
        suppliers = supplier_organization.suppliers.active
        variants = find_variants(supply_dates, suppliers)
        hash[supplier_organization.id] ||= {}
        supplier_organization.suppliers.count.times do |i|
          hash[supplier_organization.id][i] ||= {
            supplier_ids: [ "" ],
            basket_prices: variants.each_with_object({}) { |variant, prices| prices[variant.id.to_s] = "" }
          }
          next if i > 1

          hash[supplier_organization.id][i] = {
            supplier_ids: supplier_organization.suppliers.active.pluck(:id).map(&:to_s),
            basket_prices: variants.each_with_object({}) do |supply_type_variation, prices|
              prices[supply_type_variation.id.to_s] = FFaker::Random.rand(1..1000).to_s
            end
          }
        end
      end,
      "supply_dates" => [ supply_date.date.to_s ]
    }
  end
end
