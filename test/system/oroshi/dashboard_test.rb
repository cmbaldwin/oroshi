# frozen_string_literal: true

require "application_system_test_case"

class OroshiDashboardTest < ApplicationSystemTestCase
  include JavaScriptTest

  setup do
    @admin = create(:user, :admin)
    # Skip onboarding for admin user
    create(:onboarding_progress, :completed, user: @admin)
    login_as(@admin, scope: :user)
  end

  # context 'interaction with empty dashboard'
  test "loads empty dashboard" do
    visit oroshi_root_path

    assert_text "\u30DB\u30FC\u30E0"

    # #v-pills-tab .nav-link work Turbo links
    links = find("#dashboard-nav").all("a.nav-link")
    links.each do |link|
      link.click
      # text under card-title is displayed, same as link text, should be visible
      assert_selector ".card-title", text: link.text, visible: true
    end
  end

  # Modal test moved to 'full dashboard' context where data exists

  test "saves company settings" do
    visit oroshi_root_path

    # look for each input within #oroshi_dashboard_company , fill in with dummy data FFaker
    fill_in "_company_settings_name", with: FFaker::Company.name
    fill_in "_company_settings_postal_code", with: FFaker::AddressJA.postal_code
    fill_in "_company_settings_address", with: FFaker::AddressJA.address
    fill_in "_company_settings_phone", with: FFaker::PhoneNumberJA.phone_number
    fill_in "_company_settings_fax", with: FFaker::PhoneNumberJA.phone_number
    fill_in "_company_settings_mail", with: FFaker::Internet.email
    fill_in "_company_settings_web", with: FFaker::Internet.http_url
    fill_in "_company_settings_invoice_number",
            with: "T#{FFaker::Random.rand(1_000_000_000_000..9_999_999_999_999)}"

    # click elswhere to trigger save
    find("#dashboard-nav").all("a.nav-link").last.click
    find("#dashboard-nav").all("a.nav-link").first.click

    # check if the data is saved
    field_ids = %w[ _company_settings_name _company_settings_postal_code _company_settings_address
                    _company_settings_phone _company_settings_fax _company_settings_mail
                    _company_settings_web _company_settings_invoice_number]

    field_ids.each do |id|
      assert_not find("##{id}").value.empty?
    end
  end

  # context 'interaction with full dashboard'
  test "loads full dashboard" do
    create_list(:oroshi_supplier, 5)
    create(:oroshi_supply_date, :with_supplies)
    create_list(:oroshi_order, 5)

    visit oroshi_root_path

    assert_text "\u30DB\u30FC\u30E0"

    # Stats frame is currently commented out in production
    # Skip stats check until feature is re-enabled

    # #v-pills-tab .nav-link work Turbo links
    links = find("#dashboard-nav").all("a.nav-link")
    links.each do |link|
      link.click
      # text under card-title is displayed, same as link text, should be visible
      assert_selector ".card-title", text: link.text, visible: true, wait: 5
    end
  end

  test "modal pops and displays content" do
    create_list(:oroshi_supplier, 5)
    create(:oroshi_supply_date, :with_supplies)
    create_list(:oroshi_order, 5)

    visit oroshi_root_path

    # Navigate to the reception times tab first
    find("#pills-reception-times-tab", wait: 10).click

    # Wait for turbo frame to load (lazy loading)
    assert_selector "#supply_reception_times turbo-frame", wait: 15

    # Wait for the clickable element within the frame
    within("#supply_reception_times", wait: 10) do
      assert_selector '[data-turbo-frame="oroshi_modal_content"]', wait: 10
      find('[data-turbo-frame="oroshi_modal_content"]').click
    end

    # Check modal is visible (Bootstrap adds 'show' class when open)
    assert_selector "#oroshiModal.show", wait: 10

    # Verify modal content loaded
    within("#oroshiModal") do
      assert_text "\u65B0\u3057\u3044\u4F9B\u7D66\u53D7\u4ED8\u6642\u9593\u3092\u4F5C\u6210\u3059\u308B"
    end

    # Modal opened successfully - this is the main test assertion
    # Note: Closing the modal is handled separately as Bootstrap animations
    # can be flaky in headless Chrome
  end

  test "modal form submits and refreshes content for new record" do
    create_list(:oroshi_supplier, 5)
    create(:oroshi_supply_date, :with_supplies)
    create_list(:oroshi_order, 5)

    visit oroshi_root_path

    # Navigate to the reception times tab
    find("#pills-reception-times-tab", wait: 10).click

    # Wait for turbo frame to load
    assert_selector "#supply_reception_times turbo-frame", wait: 15

    # Click the modal button
    within("#supply_reception_times", wait: 10) do
      assert_selector '[data-turbo-frame="oroshi_modal_content"]', wait: 10
      find('[data-turbo-frame="oroshi_modal_content"]').click
    end

    # Wait for modal to be visible (Bootstrap adds 'show' class)
    assert_selector "#oroshiModal.show", wait: 10

    # Wait for modal body content (turbo frame) to load
    assert_selector "#oroshiModal .modal-body", wait: 10

    # Wait for form to appear - look for the form with data-refresh-target attribute
    # The form might not have the expected class due to Rails version differences
    assert_selector 'form[data-refresh-target="supply_reception_times"]', visible: true, wait: 10

    # Fill in the form
    form = find('form[data-refresh-target="supply_reception_times"]')
    form.find('input[name="oroshi_supply_reception_time[time_qualifier]"]').set("TEST")
    form.find('input[name="oroshi_supply_reception_time[hour]"]').set("11")

    # Get refresh target before submitting
    refresh_target = find("##{form['data-refresh-target']}")
    form.find('input[type="submit"]').click

    # Wait for form to process and refresh
    assert refresh_target.has_selector?('input[value="TEST"]', wait: 10)
  end

  test "activates and deactives list-group-items" do
    create_list(:oroshi_supplier, 5)
    create(:oroshi_supply_date, :with_supplies)
    create_list(:oroshi_order, 5)

    visit oroshi_root_path

    # Navigate to supplier organizations tab
    find("#dashboard-nav", wait: 10).all("a.nav-link")[1].click
    assert_selector "h3", text: "\u4F9B\u7D66\u7D44\u7E54\u30FB\u4F9B\u7D66\u8005", visible: true, wait: 10

    # Wait for supplier organizations list to load
    assert_selector "#supplier_organizations .list-group", wait: 10

    # Find the links
    links = find("#supplier_organizations").all("a.list-group-item")
    assert_includes links.first[:class], "active"

    # Click the second link
    links[1].click

    # Wait for active state to change
    sleep 0.5

    # Check if the first link no longer has active class
    assert_not_includes links.first[:class], "active"

    # Verify exactly one active link
    assert find("#supplier_organizations").has_css?("a.list-group-item.active", count: 1, wait: 5)

    # Check if the second link has the active class
    assert_includes links[1][:class], "active"
  end

  test "does not show inactive record in list-group, and can be shown by toggle" do
    create_list(:oroshi_supplier, 5)
    create(:oroshi_supply_date, :with_supplies)
    create_list(:oroshi_order, 5)

    # Create an inactive supplier_organization
    create(:oroshi_supplier_organization, active: false)
    supplier_organization_count = Oroshi::SupplierOrganization.count
    active_supplier_organization_count = Oroshi::SupplierOrganization.active.count

    visit oroshi_root_path

    # Navigate to supplier organizations tab
    assert_selector "#dashboard-nav a.nav-link", wait: 10
    find("#dashboard-nav").all("a.nav-link")[1].click
    assert_selector "h3", text: "\u4F9B\u7D66\u7D44\u7E54\u30FB\u4F9B\u7D66\u8005", visible: true, wait: 10

    # Wait for supplier organizations to load
    assert_selector "#supplier_organizations .list-group", wait: 10

    # Find the links
    links = find("#supplier_organizations", wait: 10).all("a.list-group-item")

    # Check if the count of links matches active count
    assert_equal active_supplier_organization_count, links.count

    # Click the toggle button
    find("#supplier_organizations").find("#activeToggle").click

    # Wait for inactive items to appear
    sleep 0.5

    # Check if the count now matches total count
    assert_equal supplier_organization_count, find("#supplier_organizations").all("a.list-group-item",
                                               wait: 10).count
  end
end
