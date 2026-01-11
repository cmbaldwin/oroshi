# frozen_string_literal: true

require "test_helper"

class NamespaceIsolationTest < ActiveSupport::TestCase
  test "models are namespaced under Oroshi" do
    # Check that key models exist in Oroshi namespace
    assert defined?(Oroshi::Order), "Oroshi::Order should be defined"
    assert defined?(Oroshi::Buyer), "Oroshi::Buyer should be defined"
    assert defined?(Oroshi::Product), "Oroshi::Product should be defined"
    assert defined?(Oroshi::Supplier), "Oroshi::Supplier should be defined"
  end

  test "table names have oroshi_ prefix" do
    assert_equal "oroshi_orders", Oroshi::Order.table_name
    assert_equal "oroshi_buyers", Oroshi::Buyer.table_name
    assert_equal "oroshi_products", Oroshi::Product.table_name
    assert_equal "oroshi_suppliers", Oroshi::Supplier.table_name
  end

  test "module defines table_name_prefix" do
    assert_equal "oroshi_", Oroshi.table_name_prefix
  end
end
