require "test_helper"

class Oroshi::OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
    @first_step = Oroshi::OnboardingController::ALL_STEPS.first
    @second_step = Oroshi::OnboardingController::ALL_STEPS.second
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
    assert_redirected_to oroshi_onboarding_path(@first_step)
  end

  test "index redirects to current step when one exists" do
    @user.create_onboarding_progress!(current_step: @second_step)
    get oroshi_onboarding_index_path
    assert_redirected_to oroshi_onboarding_path(@second_step)
  end

  test "show renders step form" do
    @user.create_onboarding_progress!(current_step: @first_step)
    get oroshi_onboarding_path(@first_step)
    assert_response :success
  end

  test "show redirects to index for invalid step" do
    @user.create_onboarding_progress!(current_step: @first_step)
    get oroshi_onboarding_path("invalid_step")
    assert_redirected_to oroshi_onboarding_index_path
    assert_equal "Invalid step", flash[:alert]
  end

  test "update marks step complete with valid company_info data" do
    progress = @user.create_onboarding_progress!(current_step: "company_info")
    patch oroshi_onboarding_path("company_info"), params: {
      company_settings: { name: "Test Company", postal_code: "123-4567", address: "Tokyo" }
    }
    assert progress.reload.step_completed?("company_info")
  end

  test "update advances to next step" do
    progress = @user.create_onboarding_progress!(current_step: "company_info")
    patch oroshi_onboarding_path("company_info"), params: {
      company_settings: { name: "Test Company", postal_code: "123-4567", address: "Tokyo" }
    }
    assert_equal @second_step, progress.reload.current_step
  end

  test "update redirects to next step" do
    @user.create_onboarding_progress!(current_step: "company_info")
    patch oroshi_onboarding_path("company_info"), params: {
      company_settings: { name: "Test Company", postal_code: "123-4567", address: "Tokyo" }
    }
    assert_redirected_to oroshi_onboarding_path(@second_step)
  end

  test "update on last step marks onboarding complete" do
    last_step = Oroshi::OnboardingController::ALL_STEPS.last
    Oroshi::OrderCategory.create!(name: "Test Category", color: "#3498db")
    progress = @user.create_onboarding_progress!(current_step: last_step)
    patch oroshi_onboarding_path(last_step)
    assert_not_nil progress.reload.completed_at
  end

  test "update on last step redirects to dashboard" do
    last_step = Oroshi::OnboardingController::ALL_STEPS.last
    Oroshi::OrderCategory.create!(name: "Test Category", color: "#3498db")
    @user.create_onboarding_progress!(current_step: last_step)
    patch oroshi_onboarding_path(last_step)
    assert_redirected_to oroshi_root_path
    assert_equal "Onboarding complete!", flash[:notice]
  end

  test "skip sets skipped_at" do
    progress = @user.create_onboarding_progress!(current_step: @first_step)
    post oroshi.skip_onboarding_path(@first_step)
    assert_not_nil progress.reload.skipped_at
  end

  test "skip redirects to dashboard" do
    @user.create_onboarding_progress!(current_step: @first_step)
    post oroshi.skip_onboarding_path(@first_step)
    assert_redirected_to oroshi_root_path
    assert_match(/skipped/i, flash[:notice])
  end

  test "resume clears skipped_at" do
    progress = @user.create_onboarding_progress!(current_step: @first_step, skipped_at: Time.current)
    post oroshi.resume_onboarding_path(@first_step)
    assert_nil progress.reload.skipped_at
  end

  test "resume redirects to onboarding index" do
    @user.create_onboarding_progress!(current_step: @first_step, skipped_at: Time.current)
    post oroshi.resume_onboarding_path(@first_step)
    assert_redirected_to oroshi_onboarding_index_path
    assert_match(/resuming/i, flash[:notice])
  end

  test "company_info update fails without company name" do
    @user.create_onboarding_progress!(current_step: "company_info")
    patch oroshi_onboarding_path("company_info"), params: {
      company_settings: { postal_code: "123-4567", address: "Tokyo" }
    }
    assert_response :unprocessable_entity
  end

  test "company_info saves settings to database" do
    @user.create_onboarding_progress!(current_step: "company_info")
    patch oroshi_onboarding_path("company_info"), params: {
      company_settings: {
        name: "Test Company",
        postal_code: "123-4567",
        address: "Tokyo, Japan",
        phone: "03-1234-5678"
      }
    }
    settings = Setting.find_by(name: "oroshi_company_settings")
    assert_equal "Test Company", settings.settings["name"]
    assert_equal "123-4567", settings.settings["postal_code"]
  end
end
