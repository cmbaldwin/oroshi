require "test_helper"

class Oroshi::OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  test "should redirect to sign in when not authenticated" do
    sign_out @user
    get oroshi_onboarding_index_path
    assert_redirected_to new_user_session_path
  end

  test "index creates progress if none exists" do
    assert_nil @user.onboarding_progress
    get oroshi_onboarding_index_path
    assert_not_nil @user.reload.onboarding_progress
  end

  test "index redirects to first step when no current step" do
    get oroshi_onboarding_index_path
    assert_redirected_to oroshi_onboarding_path("welcome")
  end

  test "index redirects to current step when one exists" do
    @user.create_onboarding_progress!(current_step: "company_info")
    get oroshi_onboarding_index_path
    assert_redirected_to oroshi_onboarding_path("company_info")
  end

  test "show renders step form" do
    @user.create_onboarding_progress!(current_step: "welcome")
    get oroshi_onboarding_path("welcome")
    assert_response :success
  end

  test "show redirects to index for invalid step" do
    @user.create_onboarding_progress!(current_step: "welcome")
    get oroshi_onboarding_path("invalid_step")
    assert_redirected_to oroshi_onboarding_index_path
    assert_equal "Invalid step", flash[:alert]
  end

  test "update marks step complete" do
    progress = @user.create_onboarding_progress!(current_step: "welcome")
    patch oroshi_onboarding_path("welcome")
    assert progress.reload.step_completed?("welcome")
  end

  test "update advances to next step" do
    progress = @user.create_onboarding_progress!(current_step: "welcome")
    patch oroshi_onboarding_path("welcome")
    assert_equal "company_info", progress.reload.current_step
  end

  test "update redirects to next step" do
    @user.create_onboarding_progress!(current_step: "welcome")
    patch oroshi_onboarding_path("welcome")
    assert_redirected_to oroshi_onboarding_path("company_info")
  end

  test "update on last step marks onboarding complete" do
    last_step = Oroshi::OnboardingController::ALL_STEPS.last
    progress = @user.create_onboarding_progress!(current_step: last_step)
    patch oroshi_onboarding_path(last_step)
    assert_not_nil progress.reload.completed_at
  end

  test "update on last step redirects to dashboard" do
    last_step = Oroshi::OnboardingController::ALL_STEPS.last
    @user.create_onboarding_progress!(current_step: last_step)
    patch oroshi_onboarding_path(last_step)
    assert_redirected_to oroshi_root_path
    assert_equal "Onboarding complete!", flash[:notice]
  end

  test "skip sets skipped_at" do
    progress = @user.create_onboarding_progress!(current_step: "welcome")
    post skip_oroshi_onboarding_path("welcome")
    assert_not_nil progress.reload.skipped_at
  end

  test "skip redirects to dashboard" do
    @user.create_onboarding_progress!(current_step: "welcome")
    post skip_oroshi_onboarding_path("welcome")
    assert_redirected_to oroshi_root_path
    assert_match(/skipped/i, flash[:notice])
  end

  test "resume clears skipped_at" do
    progress = @user.create_onboarding_progress!(current_step: "welcome", skipped_at: Time.current)
    post resume_oroshi_onboarding_path("welcome")
    assert_nil progress.reload.skipped_at
  end

  test "resume redirects to onboarding index" do
    @user.create_onboarding_progress!(current_step: "welcome", skipped_at: Time.current)
    post resume_oroshi_onboarding_path("welcome")
    assert_redirected_to oroshi_onboarding_index_path
    assert_match(/resuming/i, flash[:notice])
  end
end
