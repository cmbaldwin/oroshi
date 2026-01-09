# frozen_string_literal: true

require 'test_helper'

module Oroshi
  module Dashboard
    class SuppliersOrganizationsTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:user, :admin)
        sign_in @admin
      end

      test 'renders suppliers_organizations dashboard partial with turbo frames' do
        get oroshi_dashboard_suppliers_organizations_path

        assert_response :success
        assert_match(/turbo-frame[^>]*id="supplier_organizations"/, response.body)
        assert_match(/turbo-frame[^>]*id="supplier_organizations_supplier_settings"/, response.body)
      end

      test 'renders suppliers organizations dashboard with data' do
        create_list(:oroshi_supplier_organization, 2)
        create_list(:oroshi_supplier, 5)

        get oroshi_dashboard_suppliers_organizations_path

        assert_response :success
        assert_match(/turbo-frame[^>]*id="supplier_organizations"/, response.body)
      end
    end
  end
end
