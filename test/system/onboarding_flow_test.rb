# frozen_string_literal: true

require "application_system_test_case"

class OnboardingFlowTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, confirmed_at: Time.current, approved: true, role: :admin)
    # Ensure no onboarding progress exists - we're testing the onboarding flow itself
    @user.onboarding_progress&.destroy
    login_as(@user, scope: :user)
  end

  test "complete onboarding flow end-to-end" do
    visit oroshi_root_path

    # Should redirect to onboarding
    assert_selector "h2"

    # Step 1: Company Info - Test validation
    click_button "次へ"

    # Should show validation errors
    assert_selector ".alert-danger"

    # Fill in company info
    fill_in "company_settings[name]", with: "テスト株式会社"
    fill_in "company_settings[postal_code]", with: "123-4567"
    fill_in "company_settings[address]", with: "東京都渋谷区1-2-3"
    fill_in "company_settings[phone]", with: "03-1234-5678"
    fill_in "company_settings[fax]", with: "03-1234-5679"
    fill_in "company_settings[mail]", with: "test@example.com"
    fill_in "company_settings[web]", with: "www.example.com"
    fill_in "company_settings[invoice_number]", with: "T1234567890123"

    click_button "次へ"
    # Should advance to next step
    assert_no_selector ".alert-danger"
    second_step = Oroshi::OnboardingController::ALL_STEPS[1]
    assert_current_path oroshi_onboarding_path(second_step)
  end

  test "validation errors display correctly" do
    visit oroshi_onboarding_path("company_info")

    # Submit without required fields
    fill_in "company_settings[name]", with: ""
    click_button "次へ"
    assert_selector ".alert-danger"
    assert_text /会社名|必須/i

    # Form should remain on same page
    assert_current_path oroshi_onboarding_path("company_info")
  end

  test "navigate back through onboarding steps" do
    visit oroshi_onboarding_index_path

    # Complete first step
    fill_in "company_settings[name]", with: "テスト株式会社"
    fill_in "company_settings[postal_code]", with: "123-4567"
    fill_in "company_settings[address]", with: "東京都渋谷区1-2-3"
    click_button "次へ"

    # Should be on second step
    second_step = Oroshi::OnboardingController::ALL_STEPS[1]
    assert_current_path oroshi_onboarding_path(second_step)

    # Click back button
    click_link "戻る"
  end

  test "completed onboarding allows dashboard access" do
    # Mark onboarding as complete
    @user.create_onboarding_progress!(completed_at: Time.current)

    visit oroshi_root_path

    # Should load dashboard without redirect
    assert_current_path oroshi_root_path
    assert_no_selector ".onboarding-container"
  end
end
