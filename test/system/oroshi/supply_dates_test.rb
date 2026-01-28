# frozen_string_literal: true

require "application_system_test_case"

class OroshiSupplyDateTest < ApplicationSystemTestCase
  include JavaScriptTest

  setup do
    @admin = create(:user, :admin)
    # Skip onboarding for admin user
    create(:onboarding_progress, :completed, user: @admin)
    login_as(@admin, scope: :user)
  end

  # context 'interaction with empty fullcalendar'
  test "loads calendar" do
    visit oroshi_supplies_path

    # check if the calendar is loaded, the title should be in the format of yyyy年mm月
    assert_selector ".fc-toolbar-title", text: /\d{4}年\d{1,2}月/, visible: true
  end

  test "supply modal opens and closes with close button" do
    # Create required data for supplies page
    create(:oroshi_supply_date, :with_supplies)

    visit oroshi_supplies_path

    # Wait for the calendar to load
    assert_selector ".fc-toolbar-title", text: /\d{4}年\d{1,2}月/, visible: true, wait: 10

    # Click the "単価入力" button to open the modal
    find("button.fc-tankaEntry-button", wait: 10).click

    # Wait for the dialog to open
    assert_selector "dialog[data-oroshi--supplies--dialog-target='dialog'][open]", wait: 10

    # Verify modal content loaded
    assert_selector ".modal-header", text: "供給ツールパネル", wait: 10

    # Click the footer close button (閉じる)
    within("dialog[data-oroshi--supplies--dialog-target='dialog']") do
      click_button "閉じる"
    end

    # Verify the dialog is closed (no longer has 'open' attribute)
    assert_no_selector "dialog[data-oroshi--supplies--dialog-target='dialog'][open]", wait: 10
  end

  test "supply modal closes with header X button" do
    # Create required data for supplies page
    create(:oroshi_supply_date, :with_supplies)

    visit oroshi_supplies_path

    # Wait for the calendar to load
    assert_selector ".fc-toolbar-title", text: /\d{4}年\d{1,2}月/, visible: true, wait: 10

    # Click the "単価入力" button to open the modal
    find("button.fc-tankaEntry-button", wait: 10).click

    # Wait for the dialog to open
    assert_selector "dialog[data-oroshi--supplies--dialog-target='dialog'][open]", wait: 10

    # Click the header X close button
    within("dialog[data-oroshi--supplies--dialog-target='dialog']") do
      find("button.btn-close").click
    end

    # Verify the dialog is closed
    assert_no_selector "dialog[data-oroshi--supplies--dialog-target='dialog'][open]", wait: 10
  end

  test "supply modal closes when clicking backdrop" do
    # Create required data for supplies page
    create(:oroshi_supply_date, :with_supplies)

    visit oroshi_supplies_path

    # Wait for the calendar to load
    assert_selector ".fc-toolbar-title", text: /\d{4}年\d{1,2}月/, visible: true, wait: 10

    # Click the "単価入力" button to open the modal
    find("button.fc-tankaEntry-button", wait: 10).click

    # Wait for the dialog to open
    assert_selector "dialog[data-oroshi--supplies--dialog-target='dialog'][open]", wait: 10

    # Click on the backdrop (outside the modal content)
    # The dialog controller's backdropClose action handles this
    dialog = find("dialog[data-oroshi--supplies--dialog-target='dialog']")
    dialog.click(x: 10, y: 10) # Click near the edge (outside modal content)

    # Verify the dialog is closed
    assert_no_selector "dialog[data-oroshi--supplies--dialog-target='dialog'][open]", wait: 10
  end

  # NOTE: Complex FullCalendar interaction tests (drag selection, modal popups)
  # have been moved to request specs which test the underlying controller actions.
  # See test/requests/oroshi/supply_dates_test.rb and test/requests/oroshi/invoices_test.rb
end
