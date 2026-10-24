# frozen_string_literal: true

require "test_helper"

module Oroshi
  class SupplyPolicyTest < ActiveSupport::TestCase
    setup do
      @admin = create(:user, :admin)
      @managerial = create(:user, :managerial)
      @employee = create(:user, :employee)
      @supplier_user = create(:user, :supplier)

      # Setup supplier organization and suppliers
      @supplier_org = create(:oroshi_supplier_organization)
      @supplier = create(:oroshi_supplier, supplier_organization: @supplier_org, user: @supplier_user)
      @other_supplier = create(:oroshi_supplier, supplier_organization: @supplier_org)

      # Setup supplies
      @my_supply = create(:oroshi_supply, supplier: @supplier)
      @other_supply = create(:oroshi_supply, supplier: @other_supplier)
    end

    # Admin permissions
    test "admin can index supplies" do
      assert SupplyPolicy.new(@admin, Supply).index?
    end

    test "admin can show any supply" do
      assert SupplyPolicy.new(@admin, @my_supply).show?
      assert SupplyPolicy.new(@admin, @other_supply).show?
    end

    test "admin can create supply" do
      assert SupplyPolicy.new(@admin, Supply).create?
    end

    test "admin can update any supply" do
      assert SupplyPolicy.new(@admin, @my_supply).update?
      assert SupplyPolicy.new(@admin, @other_supply).update?
    end

    test "admin can destroy any supply" do
      assert SupplyPolicy.new(@admin, @my_supply).destroy?
      assert SupplyPolicy.new(@admin, @other_supply).destroy?
    end

    # Managerial permissions
    test "managerial can index supplies" do
      assert SupplyPolicy.new(@managerial, Supply).index?
    end

    test "managerial can show any supply" do
      assert SupplyPolicy.new(@managerial, @my_supply).show?
      assert SupplyPolicy.new(@managerial, @other_supply).show?
    end

    test "managerial can create supply" do
      assert SupplyPolicy.new(@managerial, Supply).create?
    end

    test "managerial can update any supply" do
      assert SupplyPolicy.new(@managerial, @my_supply).update?
      assert SupplyPolicy.new(@managerial, @other_supply).update?
    end

    test "managerial can destroy any supply" do
      assert SupplyPolicy.new(@managerial, @my_supply).destroy?
      assert SupplyPolicy.new(@managerial, @other_supply).destroy?
    end

    # Employee permissions
    test "employee can index supplies" do
      assert SupplyPolicy.new(@employee, Supply).index?
    end

    test "employee can show any supply" do
      assert SupplyPolicy.new(@employee, @my_supply).show?
      assert SupplyPolicy.new(@employee, @other_supply).show?
    end

    test "employee cannot create supply" do
      assert_not SupplyPolicy.new(@employee, Supply).create?
    end

    test "employee cannot update supply" do
      assert_not SupplyPolicy.new(@employee, @my_supply).update?
    end

    test "employee cannot destroy supply" do
      assert_not SupplyPolicy.new(@employee, @my_supply).destroy?
    end

    # Supplier permissions
    test "supplier can index supplies" do
      assert SupplyPolicy.new(@supplier_user, Supply).index?
    end

    test "supplier can show their own supply" do
      assert SupplyPolicy.new(@supplier_user, @my_supply).show?
    end

    test "supplier cannot show other supplier supply" do
      assert_not SupplyPolicy.new(@supplier_user, @other_supply).show?
    end

    test "supplier can create supply" do
      assert SupplyPolicy.new(@supplier_user, Supply).create?
    end

    test "supplier can update their own supply" do
      assert SupplyPolicy.new(@supplier_user, @my_supply).update?
    end

    test "supplier cannot update other supplier supply" do
      assert_not SupplyPolicy.new(@supplier_user, @other_supply).update?
    end

    test "supplier cannot destroy any supply" do
      assert_not SupplyPolicy.new(@supplier_user, @my_supply).destroy?
      assert_not SupplyPolicy.new(@supplier_user, @other_supply).destroy?
    end

    # Scope tests
    test "admin scope returns all supplies" do
      scope = SupplyPolicy::Scope.new(@admin, Supply.all).resolve
      assert_equal Supply.count, scope.count
    end

    test "managerial scope returns all supplies" do
      scope = SupplyPolicy::Scope.new(@managerial, Supply.all).resolve
      assert_equal Supply.count, scope.count
    end

    test "employee scope returns all supplies" do
      scope = SupplyPolicy::Scope.new(@employee, Supply.all).resolve
      assert_equal Supply.count, scope.count
    end

    test "supplier scope returns only their supplies" do
      scope = SupplyPolicy::Scope.new(@supplier_user, Supply.all).resolve
      assert_equal 1, scope.count
      assert_includes scope, @my_supply
      assert_not_includes scope, @other_supply
    end
  end
end
