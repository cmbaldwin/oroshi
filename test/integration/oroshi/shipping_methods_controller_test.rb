# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class ShippingMethodsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      sign_in @admin
    end

    # GET #index
    test 'GET index returns http success' do
      create(:oroshi_shipping_organization)
      get oroshi_shipping_methods_path
      assert_response :success
    end

    # GET #edit
    test 'GET edit returns http success' do
      shipping_method = create(:oroshi_shipping_method)
      get edit_oroshi_shipping_method_path(shipping_method)
      assert_response :success
    end

    # GET #new
    test 'GET new returns http success' do
      get new_oroshi_shipping_method_path
      assert_response :success
    end

    # POST #create
    test 'POST create returns http success with valid params' do
      create(:oroshi_shipping_organization)
      shipping_method_attributes = attributes_for(:oroshi_shipping_method,
                                                  shipping_organization_id: Oroshi::ShippingOrganization.first.id)
      post oroshi_shipping_methods_path, params: { oroshi_shipping_method: shipping_method_attributes }
    end

    test 'POST create returns http unprocessable_entity with invalid params' do
      shipping_method_attributes = attributes_for(:oroshi_shipping_method, company_name: nil)
      post oroshi_shipping_methods_path, params: { oroshi_shipping_method: shipping_method_attributes }
      assert_response :unprocessable_entity
    end

    # PATCH #update
    test 'PATCH update returns http success' do
      shipping_method = create(:oroshi_shipping_method)
      updated_attributes = attributes_for(:oroshi_shipping_method, company_name: 'Updated Company Name')
      patch oroshi_shipping_method_path(shipping_method), params: { oroshi_shipping_method: updated_attributes }
      assert_response :success
    end
  end
end
