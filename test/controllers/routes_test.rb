# frozen_string_literal: true

require "test_helper"

class RoutesTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, confirmed_at: Time.current, approved: true, role: :admin)
    # Create completed onboarding progress to avoid redirects
    @user.create_onboarding_progress!(completed_at: Time.current)
    sign_in @user
  end

  test "root route should load dashboard" do
    get root_path
    assert_response :success
  end

  test "oroshi root should load dashboard for user with completed onboarding" do
    get oroshi_root_path
    assert_response :success
  end

  test "new user without onboarding should redirect to onboarding" do
    @user.onboarding_progress.update!(completed_at: nil, skipped_at: nil)
    get oroshi_root_path
    assert_response :redirect
    assert_redirected_to oroshi_onboarding_index_path
  end

  test "onboarding index should redirect to first step" do
    get oroshi_onboarding_index_path
    assert_response :redirect
    first_step = Oroshi::OnboardingController::ALL_STEPS.first
    assert_redirected_to oroshi_onboarding_path(first_step)
  end

  test "legal routes should be accessible without authentication" do
    sign_out @user

    get privacy_policy_path
    assert_response :success

    get terms_of_service_path
    assert_response :success
  end
end
