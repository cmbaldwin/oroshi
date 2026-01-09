# frozen_string_literal: true

require "test_helper"

class Oroshi::SupplyTest < ActiveSupport::TestCase
  def setup
    @supply = build(:oroshi_supply)
  end

  test "is valid with valid attributes" do
    assert @supply.valid?
  end

  # Validation Tests
  test "is not valid without a supply_date_id" do
    @supply.supply_date_id = nil
    assert_not @supply.valid?
  end

  test "is not valid without a supplier_id" do
    @supply.supplier_id = nil
    assert_not @supply.valid?
  end

  test "is not valid without a supply_type_variation_id" do
    @supply.supply_type_variation_id = nil
    assert_not @supply.valid?
  end

  test "is not valid without a supply_reception_time_id" do
    @supply.supply_reception_time_id = nil
    assert_not @supply.valid?
  end

  # Association Assignments
  test "has supplier organization" do
    supply = create(:oroshi_supply)
    assert_instance_of Oroshi::SupplierOrganization, supply.supplier_organization
  end

  test "has supplier" do
    supply = create(:oroshi_supply)
    assert_instance_of Oroshi::Supplier, supply.supplier
  end

  test "has supply dates" do
    supply = create(:oroshi_supply)
    assert_instance_of Oroshi::SupplyDate, supply.supply_date
  end

  test "has supply types" do
    supply = create(:oroshi_supply)
    assert_instance_of Oroshi::SupplyType, supply.supply_type
  end

  test "has supply type variations" do
    supply = create(:oroshi_supply)
    assert_instance_of Oroshi::SupplyTypeVariation, supply.supply_type_variation
  end

  # after_save
  test "creates and updates supply_type and supply_type_variation joins when a supply is created" do
    supply_type = create(:oroshi_supply_type)
    supply_type_variation = create(:oroshi_supply_type_variation, supply_type: supply_type)
    supply_date = create(:oroshi_supply_date)
    quantity = 10

    assert_difference [ "Oroshi::SupplyDate::SupplyType.count", "Oroshi::SupplyDate::SupplyTypeVariation.count" ], 1 do
      create(:oroshi_supply, supply_date: supply_date,
                             supply_type_variation: supply_type_variation,
                             quantity: quantity)
    end

    supply_type_join = Oroshi::SupplyDate::SupplyType.find_by(supply_date: supply_date, supply_type: supply_type)
    assert_equal quantity, supply_type_join.total

    supply_type_variation_join = Oroshi::SupplyDate::SupplyTypeVariation.find_by(supply_date: supply_date,
                                                                                 supply_type_variation: supply_type_variation)
    assert_equal quantity, supply_type_variation_join.total
  end
end
