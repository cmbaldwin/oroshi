# frozen_string_literal: true

require "test_helper"

module Oroshi
  class OrderPolicyTest < ActiveSupport::TestCase
    setup do
      @admin = create(:user, :admin)
      @managerial = create(:user, :managerial)
      @employee = create(:user, :employee)
      @supplier_user = create(:user, :supplier)
      @unapproved = create(:user, approved: false)

      @order = create(:oroshi_order)
    end

    # Admin permissions
    test "admin can index orders" do
      assert OrderPolicy.new(@admin, Order).index?
    end

    test "admin can show order" do
      assert OrderPolicy.new(@admin, @order).show?
    end

    test "admin can create order" do
      assert OrderPolicy.new(@admin, Order).create?
    end

    test "admin can update order" do
      assert OrderPolicy.new(@admin, @order).update?
    end

    test "admin can destroy order" do
      assert OrderPolicy.new(@admin, @order).destroy?
    end

    # Managerial permissions
    test "managerial can index orders" do
      assert OrderPolicy.new(@managerial, Order).index?
    end

    test "managerial can show order" do
      assert OrderPolicy.new(@managerial, @order).show?
    end

    test "managerial can create order" do
      assert OrderPolicy.new(@managerial, Order).create?
    end

    test "managerial can update order" do
      assert OrderPolicy.new(@managerial, @order).update?
    end

    test "managerial can destroy order" do
      assert OrderPolicy.new(@managerial, @order).destroy?
    end

    # Employee permissions
    test "employee can index orders" do
      assert OrderPolicy.new(@employee, Order).index?
    end

    test "employee can show order" do
      assert OrderPolicy.new(@employee, @order).show?
    end

    test "employee cannot create order" do
      assert_not OrderPolicy.new(@employee, Order).create?
    end

    test "employee cannot update order" do
      assert_not OrderPolicy.new(@employee, @order).update?
    end

    test "employee cannot destroy order" do
      assert_not OrderPolicy.new(@employee, @order).destroy?
    end

    # Supplier permissions
    test "supplier cannot index orders" do
      assert_not OrderPolicy.new(@supplier_user, Order).index?
    end

    test "supplier cannot show order" do
      assert_not OrderPolicy.new(@supplier_user, @order).show?
    end

    test "supplier cannot create order" do
      assert_not OrderPolicy.new(@supplier_user, Order).create?
    end

    test "supplier cannot update order" do
      assert_not OrderPolicy.new(@supplier_user, @order).update?
    end

    test "supplier cannot destroy order" do
      assert_not OrderPolicy.new(@supplier_user, @order).destroy?
    end

    # Scope tests
    test "admin scope returns all orders" do
      scope = OrderPolicy::Scope.new(@admin, Order.all).resolve
      assert_equal Order.count, scope.count
    end

    test "managerial scope returns all orders" do
      scope = OrderPolicy::Scope.new(@managerial, Order.all).resolve
      assert_equal Order.count, scope.count
    end

    test "employee scope returns all orders" do
      scope = OrderPolicy::Scope.new(@employee, Order.all).resolve
      assert_equal Order.count, scope.count
    end

    test "supplier scope returns no orders" do
      scope = OrderPolicy::Scope.new(@supplier_user, Order.all).resolve
      assert_equal 0, scope.count
    end
  end
end
