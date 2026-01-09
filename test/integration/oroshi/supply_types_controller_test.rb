# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class SupplyTypesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      sign_in @admin
    end

    # GET #index
    test 'GET index returns a success response' do
      get oroshi_supply_types_path
      assert_response :success
    end

    # GET #load
    test 'GET load returns a success response' do
      get load_oroshi_supply_types_path
      assert_response :success
    end

    # GET #new
    test 'GET new returns a success response' do
      get new_oroshi_supply_type_path
      assert_response :success
    end

    # POST #create
    test 'POST create returns http success with valid params' do
      supply_type_attributes = attributes_for(:oroshi_supply_type)
      post oroshi_supply_types_path, params: { oroshi_supply_type: supply_type_attributes }
    end

    test 'POST create returns http unprocessable_entity with invalid params' do
      supply_type_attributes = attributes_for(:oroshi_supply_type, name: nil)
      post oroshi_supply_types_path, params: { oroshi_supply_type: supply_type_attributes }
      assert_response :unprocessable_entity
    end

    # PATCH #update
    test 'PATCH update returns http success' do
      supply_type = create(:oroshi_supply_type)
      updated_attributes = attributes_for(:oroshi_supply_type, name: 'Updated Supply Type Name')
      patch oroshi_supply_type_path(supply_type), params: { oroshi_supply_type: updated_attributes }
      assert_response :success
    end
  end
end
