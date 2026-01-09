# frozen_string_literal: true

require "application_system_test_case"

class OroshiSupplyDateTest < ApplicationSystemTestCase
  include JavaScriptTest

  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # context 'interaction with empty fullcalendar'
  test "loads calendar" do
    visit oroshi_supplies_path

    # check if the calendar is loaded, the title should be in the format of yyyy年mm月
    assert_selector ".fc-toolbar-title", text: /\d{4}年\d{1,2}月/, visible: true
  end

  # NOTE: Complex FullCalendar interaction tests (drag selection, modal popups)
  # have been moved to request specs which test the underlying controller actions.
  # See test/requests/oroshi/supply_dates_test.rb and test/requests/oroshi/invoices_test.rb
end
