# frozen_string_literal: true

require "application_system_test_case"

# NOTE: This system spec tests FullCalendar UI interactions which are inherently flaky.
# The core functionality (supply CRUD) is tested in test/requests/oroshi/supplies_test.rb
# and test/requests/oroshi/supply_dates_test.rb. Skip flaky tests for CI stability.
class OroshiSupplyDateShowTest < ApplicationSystemTestCase
  include JavaScriptTest

  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # context 'interaction with calendar'
  test "creates and shows empty Supply Date from calendar" do
    visit oroshi_supplies_path

    # find a .fc-daygrid-day-frame and click it (fullcalendar responds to interaction on this node)
    find(".fc-daygrid-day-frame", match: :first).click
    # page should have text '牡蠣供給記載表'
    assert_text "\u7261\u8823\u4F9B\u7D66\u8A18\u8F09\u8868"
  end
end
