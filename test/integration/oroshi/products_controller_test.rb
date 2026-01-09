# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class ProductsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      sign_in @admin
    end

    # GET #index
    test 'GET index returns http success' do
      get oroshi_products_path
      assert_response :success
    end

    # GET #new
    test 'GET new returns http success' do
      get new_oroshi_product_path
      assert_response :success
    end

    # POST #create
    test 'POST create returns http success with valid params' do
      supply_type = create(:oroshi_supply_type)
      product_attributes = attributes_for(:oroshi_product, supply_type_id: supply_type.id)
      post oroshi_products_path, params: { oroshi_product: product_attributes }
      assert_response :success
    end

    test 'POST create returns http unprocessable_entity with invalid params' do
      product_attributes = attributes_for(:oroshi_product, name: nil)
      post oroshi_products_path, params: { oroshi_product: product_attributes }
      assert_response :unprocessable_entity
    end

    # PATCH #update
    test 'PATCH update returns http success' do
      product = create(:oroshi_product)
      updated_attributes = attributes_for(:oroshi_product, name: 'Updated Name')
      patch oroshi_product_path(product), params: { oroshi_product: updated_attributes }
      assert_response :success
    end
  end
end
