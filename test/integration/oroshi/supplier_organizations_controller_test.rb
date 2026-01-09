# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class SupplierOrganizationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      sign_in @admin
    end

    # GET #index
    test 'GET index returns http success' do
      get oroshi_supplier_organizations_path
      assert_response :success
    end

    # GET #load
    test 'GET load returns http success' do
      get load_oroshi_supplier_organizations_path
      assert_response :success
    end

    # GET #new
    test 'GET new returns http success' do
      get new_oroshi_supplier_organization_path
      assert_response :success
    end

    # POST #create
    test 'POST create returns http success with valid params' do
      supplier_organization_attributes = attributes_for(:oroshi_supplier_organization)
      post oroshi_supplier_organizations_path,
           params: { oroshi_supplier_organization: supplier_organization_attributes }
      assert_response :success
    end

    test 'POST create returns http unprocessable_entity with invalid params' do
      supplier_organization_attributes = attributes_for(:oroshi_supplier_organization, entity_name: nil)
      post oroshi_supplier_organizations_path,
           params: { oroshi_supplier_organization: supplier_organization_attributes }
      assert_response :unprocessable_entity
    end

    # PATCH #update
    test 'PATCH update returns http success' do
      supplier_organization = create(:oroshi_supplier_organization)
      updated_attributes = attributes_for(:oroshi_supplier_organization, name: 'Updated Name')
      patch oroshi_supplier_organization_path(supplier_organization),
            params: { oroshi_supplier_organization: updated_attributes }
      assert_response :success
    end
  end
end
