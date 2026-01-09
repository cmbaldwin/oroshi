# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class SupplyDatesControllerTest < ActionDispatch::IntegrationTest
    include Oroshi::SuppliesHelper

    setup do
      @admin = create(:user, :admin)
      sign_in @admin
    end

    # GET #entry
    test 'GET entry returns http success' do
      supply_date = create(:oroshi_supply_date)
      supplier_organization = create(:oroshi_supplier_organization)
      supply_reception_time = create(:oroshi_supply_reception_time)
      get oroshi_supply_dates_entry_path, params: {
        date: supply_date.date,
        supplier_organization_id: supplier_organization.id,
        supply_reception_time_id: supply_reception_time.id
      }, as: :turbo_stream
      assert_response :success
    end

    # GET #checklist
    test 'GET checklist returns http success' do
      get oroshi_supply_dates_checklist_path, params: {
        date: '2022-01-01',
        subregion_ids: ['1'],
        supply_reception_time_ids: ['1']
      }
      assert_response :success
    end

    # GET #supply_price_actions
    test 'GET supply_price_actions returns http success' do
      get oroshi_supply_dates_supply_price_actions_path, as: :turbo_stream
      assert_response :ok
    end

    # GET #supply_invoice_actions
    test 'GET supply_invoice_actions returns http success' do
      supply_date = create(:oroshi_supply_date)
      get oroshi_supply_dates_supply_invoice_actions_path, params: {
        supply_dates: [supply_date.date]
      }, as: :turbo_stream
      assert_response :ok
    end

    # GET #set_supply_prices
    test 'GET set_supply_prices returns http success and sets supply prices' do
      supply_date = create(:oroshi_supply_date, :with_supplies, zero_price: true)
      supply_dates = [supply_date]
      set_supply_price_params = build_set_supply_price_params(supply_date, supply_dates)

      assert supply_date.supply.count.positive?
      get oroshi_supply_dates_set_supply_prices_path, params: set_supply_price_params, as: :turbo_stream
      assert_response :success
      assert_equal 0, supply_date.incomplete_supply.count
    end

    private

    def build_set_supply_price_params(supply_date, supply_dates)
      {
        'prices' =>
        supply_date.supplier_organizations.each_with_object({}) do |supplier_organization, hash|
          suppliers = supplier_organization.suppliers.active
          variants = find_variants(supply_dates, suppliers)
          hash[supplier_organization.id] ||= {}
          supplier_organization.suppliers.count.times do |i|
            hash[supplier_organization.id][i] ||= {
              supplier_ids: [''],
              basket_prices: variants.each_with_object({}) { |variant, prices| prices[variant.id.to_s] = '' }
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
        'supply_dates' => [supply_date.date.to_s]
      }
    end
  end
end
