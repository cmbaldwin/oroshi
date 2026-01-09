# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class SuppliersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      sign_in @admin
    end

    # GET #index
    test 'GET index returns http success' do
      create(:oroshi_supplier_organization)
      get oroshi_suppliers_path
      assert_response :success
    end

    # GET #edit
    test 'GET edit returns http success' do
      supplier = create(:oroshi_supplier)
      get edit_oroshi_supplier_path(supplier)
      assert_response :success
    end

    # GET #new
    test 'GET new returns http success' do
      get new_oroshi_supplier_path
      assert_response :success
    end

    # POST #create
    test 'POST create returns http success with valid params' do
      create(:oroshi_supplier_organization)
      supplier_attributes = attributes_for(:oroshi_supplier,
                                           supplier_organization_id: Oroshi::SupplierOrganization.first.id)
      post oroshi_suppliers_path, params: { oroshi_supplier: supplier_attributes }
    end

    test 'POST create returns http unprocessable_entity with invalid params' do
      supplier_attributes = attributes_for(:oroshi_supplier, company_name: nil)
      post oroshi_suppliers_path, params: { oroshi_supplier: supplier_attributes }
      assert_response :unprocessable_entity
    end

    # PATCH #update
    test 'PATCH update returns http success' do
      supplier = create(:oroshi_supplier)
      updated_attributes = attributes_for(:oroshi_supplier, company_name: 'Updated Company Name')
      patch oroshi_supplier_path(supplier), params: { oroshi_supplier: updated_attributes }
      assert_response :success
    end
  end
end
