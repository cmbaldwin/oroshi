# frozen_string_literal: true

require "application_system_test_case"

class Oroshi::NavigationTest < ApplicationSystemTestCase
  include JavaScriptTest

  setup do
    @user = create(:user, :admin)
    # Skip onboarding for admin user
    create(:onboarding_progress, :completed, user: @user)
    login_as(@user, scope: :user)
  end

  test "navigates through all navbar and dashboard links without errors" do
    visit oroshi_root_path
    assert_selector "#navbar_t"
    assert_selector "#dashboard-nav"

    # Test all links in the top navbar
    within("#navbar_t") do
      nav_links = all("a.nav-link")

      nav_links.each_with_index do |link, index|
        # Get the link text and href for debugging
        link_text = link.text.strip
        link_href = link[:href]

        puts "Clicking navbar link #{index + 1}/#{nav_links.length}: '#{link_text}' (#{link_href})"

        # Click the link
        link.click
      end
    end

    # After clicking all navbar links, verify we can still see the navbar
    # and that there are no error messages on the final page
    assert_selector "#navbar_t"
    assert_no_selector ".alert-danger", text: /error/i
    assert_no_text "Something went wrong"
    assert_no_text "404"
    assert_no_text "500"

    # Navigate back to dashboard for dashboard-nav tests
    visit oroshi_root_path
    assert_selector "#dashboard-nav"

    # Test all links in the dashboard navigation
    within("#dashboard-nav") do
      dashboard_links = all("a.nav-link")

      dashboard_links.each_with_index do |link, index|
        link_text = link.text.strip

        puts "Clicking dashboard link #{index + 1}/#{dashboard_links.length}: '#{link_text}'"

        # Click the link
        link.click

        # Wait for content to load (Turbo frame or full page)
        sleep 0.5 # Allow Turbo to complete
      end
    end

    # After clicking all dashboard links, verify no errors
    assert_selector "#dashboard-nav"
    assert_no_selector ".alert-danger"
    assert_no_text "Something went wrong"
    assert_no_text "404"
    assert_no_text "500"

    puts "✅ All navigation links tested successfully"
  end
end
