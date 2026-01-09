# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class ProductionZonesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      sign_in @admin
    end

    # GET #index
    test 'GET index returns http success' do
      get oroshi_production_zones_path
      assert_response :success
    end

    # GET #new
    test 'GET new returns http success' do
      get new_oroshi_production_zone_path
      assert_response :success
    end

    # POST #create
    test 'POST create returns http success with valid params' do
      production_zone_attributes = attributes_for(:oroshi_production_zone)
      post oroshi_production_zones_path, params: { oroshi_production_zone: production_zone_attributes }
      assert_response :success
    end

    test 'POST create returns http unprocessable_entity with invalid params' do
      production_zone_attributes = attributes_for(:oroshi_production_zone, name: nil)
      post oroshi_production_zones_path, params: { oroshi_production_zone: production_zone_attributes }
      assert_response :unprocessable_entity
    end

    # PATCH #update
    test 'PATCH update returns http success' do
      production_zone = create(:oroshi_production_zone)
      updated_attributes = attributes_for(:oroshi_production_zone, name: 'Updated Name')
      patch oroshi_production_zone_path(production_zone), params: { oroshi_production_zone: updated_attributes }
      assert_response :success
    end
  end
end
