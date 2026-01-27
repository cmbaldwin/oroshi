# frozen_string_literal: true

require "test_helper"

module Oroshi
  class SupplierPolicyTest < ActiveSupport::TestCase
    setup do
      @admin = create(:user, :admin)
      @vip = create(:user, :vip)
      @employee = create(:user, :employee)
      @supplier_user = create(:user, :supplier)

      # Setup supplier organization and suppliers
      @supplier_org = create(:oroshi_supplier_organization)
      @my_supplier = create(:oroshi_supplier, supplier_organization: @supplier_org, user: @supplier_user)
      @other_supplier = create(:oroshi_supplier, supplier_organization: @supplier_org)
    end

    # Admin permissions
    test "admin can index suppliers" do
      assert SupplierPolicy.new(@admin, Supplier).index?
    end

    test "admin can show any supplier" do
      assert SupplierPolicy.new(@admin, @my_supplier).show?
      assert SupplierPolicy.new(@admin, @other_supplier).show?
    end

    test "admin can create supplier" do
      assert SupplierPolicy.new(@admin, Supplier).create?
    end

    test "admin can update any supplier" do
      assert SupplierPolicy.new(@admin, @my_supplier).update?
      assert SupplierPolicy.new(@admin, @other_supplier).update?
    end

    test "admin can destroy any supplier" do
      assert SupplierPolicy.new(@admin, @my_supplier).destroy?
      assert SupplierPolicy.new(@admin, @other_supplier).destroy?
    end

    # VIP permissions
    test "vip can index suppliers" do
      assert SupplierPolicy.new(@vip, Supplier).index?
    end

    test "vip can show any supplier" do
      assert SupplierPolicy.new(@vip, @my_supplier).show?
      assert SupplierPolicy.new(@vip, @other_supplier).show?
    end

    test "vip can create supplier" do
      assert SupplierPolicy.new(@vip, Supplier).create?
    end

    test "vip can update any supplier" do
      assert SupplierPolicy.new(@vip, @my_supplier).update?
      assert SupplierPolicy.new(@vip, @other_supplier).update?
    end

    test "vip can destroy any supplier" do
      assert SupplierPolicy.new(@vip, @my_supplier).destroy?
      assert SupplierPolicy.new(@vip, @other_supplier).destroy?
    end

    # Employee permissions
    test "employee can index suppliers" do
      assert SupplierPolicy.new(@employee, Supplier).index?
    end

    test "employee can show any supplier" do
      assert SupplierPolicy.new(@employee, @my_supplier).show?
      assert SupplierPolicy.new(@employee, @other_supplier).show?
    end

    test "employee cannot create supplier" do
      assert_not SupplierPolicy.new(@employee, Supplier).create?
    end

    test "employee cannot update supplier" do
      assert_not SupplierPolicy.new(@employee, @my_supplier).update?
    end

    test "employee cannot destroy supplier" do
      assert_not SupplierPolicy.new(@employee, @my_supplier).destroy?
    end

    # Supplier permissions
    test "supplier can index suppliers" do
      assert SupplierPolicy.new(@supplier_user, Supplier).index?
    end

    test "supplier can show their own supplier record" do
      assert SupplierPolicy.new(@supplier_user, @my_supplier).show?
    end

    test "supplier cannot show other supplier record" do
      assert_not SupplierPolicy.new(@supplier_user, @other_supplier).show?
    end

    test "supplier cannot create supplier" do
      assert_not SupplierPolicy.new(@supplier_user, Supplier).create?
    end

    test "supplier can update their own supplier record" do
      assert SupplierPolicy.new(@supplier_user, @my_supplier).update?
    end

    test "supplier cannot update other supplier record" do
      assert_not SupplierPolicy.new(@supplier_user, @other_supplier).update?
    end

    test "supplier cannot destroy any supplier" do
      assert_not SupplierPolicy.new(@supplier_user, @my_supplier).destroy?
      assert_not SupplierPolicy.new(@supplier_user, @other_supplier).destroy?
    end

    # Scope tests
    test "admin scope returns all suppliers" do
      scope = SupplierPolicy::Scope.new(@admin, Supplier.all).resolve
      assert_equal Supplier.count, scope.count
    end

    test "vip scope returns all suppliers" do
      scope = SupplierPolicy::Scope.new(@vip, Supplier.all).resolve
      assert_equal Supplier.count, scope.count
    end

    test "employee scope returns all suppliers" do
      scope = SupplierPolicy::Scope.new(@employee, Supplier.all).resolve
      assert_equal Supplier.count, scope.count
    end

    test "supplier scope returns only their supplier record" do
      scope = SupplierPolicy::Scope.new(@supplier_user, Supplier.all).resolve
      assert_equal 1, scope.count
      assert_includes scope, @my_supplier
      assert_not_includes scope, @other_supplier
    end
  end
end
