# frozen_string_literal: true

require "test_helper"

class Oroshi::SupplyDateTest < ActiveSupport::TestCase
  def setup
    @supply_date = build(:oroshi_supply_date)
  end

  test "is valid with valid attributes" do
    assert @supply_date.valid?
  end

  # Validations
  test "is not valid without a date" do
    @supply_date.date = nil
    assert_not @supply_date.valid?
  end

  # Association Assignments
  test "has supplier organizations" do
    supply_date = create(:oroshi_supply_date, :with_supplies)
    assert_operator supply_date.supplier_organizations.length, :>, 0
  end

  test "has suppliers" do
    supply_date = create(:oroshi_supply_date, :with_supplies)
    assert_operator supply_date.suppliers.length, :>, 0
  end

  test "has supplies" do
    supply_date = create(:oroshi_supply_date, :with_supplies)
    assert_operator supply_date.supplies.length, :>, 0
  end

  test "has supply types" do
    supply_date = create(:oroshi_supply_date, :with_supplies)
    assert_operator supply_date.supply_types.length, :>, 0
  end

  test "has supply type variations" do
    supply_date = create(:oroshi_supply_date, :with_supplies)
    assert_operator supply_date.supply_type_variations.length, :>, 0
  end
end
