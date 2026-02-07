# frozen_string_literal: true

require "test_helper"

class Oroshi::AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    @vip = create(:user, :vip)
    @supplier_user = create(:user, :supplier)
    @employee = create(:user, :employee)
    @unapproved = create(:user, role: :user, approved: false)

    # Setup associated data (using oroshi_ prefix for namespaced factories)
    @supplier_org = create(:oroshi_supplier_organization)
    @supplier = create(:oroshi_supplier, supplier_organization: @supplier_org, user: @supplier_user)

    @other_supplier_org = create(:oroshi_supplier_organization)
    @other_supplier = create(:oroshi_supplier, supplier_organization: @other_supplier_org)

    # Skip onboarding for all users to avoid redirect issues
    [ @admin, @vip, @supplier_user, @employee, @unapproved ].each do |user|
      create(:onboarding_progress, :completed, user: user)
    end
  end

  test "unapproved user is blocked" do
    sign_in @unapproved
    get oroshi_dashboard_home_path
    # Should redirect to root with auth notice (not forbidden in this app)
    assert_response :redirect
  end

  test "admin has full access" do
    sign_in @admin
    get oroshi_dashboard_home_path
    assert_response :success
  end

  test "vip has full access" do
    sign_in @vip
    get oroshi_dashboard_home_path
    assert_response :success
  end

  test "supplier can access dashboard" do
    sign_in @supplier_user
    get oroshi_root_path
    assert_response :success
  end

  test "employee can access dashboard" do
    sign_in @employee
    get oroshi_root_path
    assert_response :success
  end
end
