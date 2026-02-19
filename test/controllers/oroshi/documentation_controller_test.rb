# frozen_string_literal: true

require "test_helper"

class Oroshi::DocumentationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    create(:onboarding_progress, :completed, user: @admin)
    sign_in @admin
  end

  # === Index ===

  test "GET documentation index returns http success in Japanese" do
    get oroshi.documentation_index_path(locale: :ja)
    assert_response :success
  end

  test "GET documentation index returns http success in English" do
    get oroshi.documentation_index_path(locale: :en)
    assert_response :success
  end

  # === Section Index Pages ===

  Oroshi::DocumentationController::ALL_SECTIONS.each do |section|
    test "GET documentation section #{section} returns http success in Japanese" do
      get oroshi.documentation_section_path(section: section, locale: :ja)
      assert_response :success
    end

    test "GET documentation section #{section} returns http success in English" do
      get oroshi.documentation_section_path(section: section, locale: :en)
      assert_response :success
    end
  end

  # === Individual Pages ===

  Oroshi::DocumentationController::SECTIONS.each do |section, pages|
    pages.each do |page|
      test "GET documentation page #{section}/#{page} returns http success in Japanese" do
        get oroshi.documentation_page_path(section: section, page: page, locale: :ja)
        assert_response :success
      end

      test "GET documentation page #{section}/#{page} returns http success in English" do
        get oroshi.documentation_page_path(section: section, page: page, locale: :en)
        assert_response :success
      end
    end
  end

  # === Error Handling ===

  test "GET invalid section redirects with alert" do
    get oroshi.documentation_section_path(section: "nonexistent", locale: :ja)
    assert_redirected_to oroshi.documentation_index_path
    assert_equal I18n.t("oroshi.documentation.messages.invalid_section"), flash[:alert]
  end

  test "GET invalid page redirects with alert" do
    get oroshi.documentation_page_path(section: "orders", page: "nonexistent", locale: :ja)
    assert_redirected_to oroshi.documentation_section_path(section: "orders")
    assert_equal I18n.t("oroshi.documentation.messages.invalid_page"), flash[:alert]
  end

  # === Authentication ===

  test "unauthenticated user is redirected" do
    sign_out @admin
    get oroshi.documentation_index_path
    assert_response :redirect
  end
end
