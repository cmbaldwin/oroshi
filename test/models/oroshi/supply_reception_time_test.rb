# frozen_string_literal: true

require "test_helper"

class Oroshi::SupplyReceptionTimeTest < ActiveSupport::TestCase
  def setup
    @supply_reception_time = build(:oroshi_supply_reception_time)
  end

  test "is valid with valid attributes" do
    assert @supply_reception_time.valid?
  end

  # Validations
  test "is not valid without an hour" do
    @supply_reception_time.hour = nil
    assert_not @supply_reception_time.valid?
  end

  test "is not valid without a time_qualifier" do
    @supply_reception_time.time_qualifier = nil
    assert_not @supply_reception_time.valid?
  end
end
