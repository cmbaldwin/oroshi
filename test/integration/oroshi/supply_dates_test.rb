# frozen_string_literal: true

require "test_helper"

module Oroshi
  # NOTE: Complex turbo_stream modal endpoints (supply_price_actions, supply_invoice_actions,
  # set_supply_prices) render through the oroshi/supplies/modal/ views which are tested
  # at the integration/system level. Request specs here verify the basic GET endpoints
  # and model integration.
  class SupplyDatesTest < ActionDispatch::IntegrationTest
    setup do
      @user = create(:user, :admin)
      sign_in @user

      @supplier_org = create(:oroshi_supplier_organization)
      @supplier = create(:oroshi_supplier, supplier_organization: @supplier_org)
      @supply_date = create(:oroshi_supply_date, date: Time.zone.today)
      @supply_type_variation = @supplier.supply_type_variations.first
      @reception_time = @supplier_org.supply_reception_times.first
      @supply = create(:oroshi_supply,
                       supply_date: @supply_date,
                       supplier: @supplier,
                       supply_type_variation: @supply_type_variation,
                       supply_reception_time: @reception_time,
                       quantity: 10,
                       price: 100)
    end

    test "GET /oroshi/supply_dates/:date returns success for existing supply date" do
      get oroshi_supply_date_path(date: @supply_date.date.to_s)
      assert_response :success
    end

    test "creates and shows supply date for new date" do
      new_date = Time.zone.today + 30.days

      assert_difference("Oroshi::SupplyDate.count", 1) do
        get oroshi_supply_date_path(date: new_date.to_s)
      end
      assert_response :success
    end

    test "associates supplies with supply date" do
      assert_includes @supply_date.supplies, @supply
    end

    test "tracks supplier organizations through supplies" do
      assert_includes @supply_date.supplier_organizations, @supplier_org
    end

    test "can update supply prices" do
      original_price = @supply.price
      @supply.update!(price: 200)
      @supply.reload

      assert_equal 200, @supply.price
      refute_equal original_price, @supply.price
    end

    test "validates price is non-negative" do
      @supply.price = -10
      refute @supply.valid?
    end

    test "validates price is present" do
      @supply.price = nil
      refute @supply.valid?
    end
  end
end
