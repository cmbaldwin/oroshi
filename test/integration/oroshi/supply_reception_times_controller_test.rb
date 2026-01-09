# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class SupplyReceptionTimesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      sign_in @admin
    end

    # GET #index
    test 'GET index returns http success' do
      get oroshi_supply_reception_times_path
      assert_response :success
    end

    # GET #new
    test 'GET new returns http success' do
      get new_oroshi_supply_reception_time_path
      assert_response :success
    end

    # POST #create
    test 'POST create returns http success with valid params' do
      supply_reception_time_attributes = attributes_for(:oroshi_supply_reception_time)
      post oroshi_supply_reception_times_path,
           params: { oroshi_supply_reception_time: supply_reception_time_attributes }
      assert_response :success
    end

    test 'POST create returns http unprocessable_entity with invalid params' do
      supply_reception_time_attributes = attributes_for(:oroshi_supply_reception_time, hour: nil)
      post oroshi_supply_reception_times_path,
           params: { oroshi_supply_reception_time: supply_reception_time_attributes }
      assert_response :unprocessable_entity
    end

    # PATCH #update
    test 'PATCH update returns http success' do
      supply_reception_time = create(:oroshi_supply_reception_time)
      updated_attributes = attributes_for(:oroshi_supply_reception_time, hour: 10)
      patch oroshi_supply_reception_time_path(supply_reception_time),
            params: { oroshi_supply_reception_time: updated_attributes }
      assert_response :success
    end
  end
end
