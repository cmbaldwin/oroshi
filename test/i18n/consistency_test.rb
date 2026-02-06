# frozen_string_literal: true

require "test_helper"

class I18nConsistencyTest < ActiveSupport::TestCase
  test "critical Japanese translations are not empty" do
    keys_and_samples = {
      "oroshi.payment_receipts.dashboard.no_outstanding_buyers" => "支払い",
      "oroshi.supplies.modal.panel_title" => "供給",
      "oroshi.onboarding.messages.step_completed" => "ステップ",
      "oroshi.orders.modal.panel_title" => "注文",
      "common.buttons.close" => "閉じる",
      "oroshi.material_categories.index.page_title" => "製造",
      "mailers.invoices.greeting" => "お世話"
    }

    keys_and_samples.each do |key, expected_substring|
      value = I18n.t(key)
      assert_not_empty value, "#{key} translation is empty"
      assert_includes value, expected_substring, "#{key} translation may be incorrect: expected substring '#{expected_substring}' not found in '#{value}'"
    end
  end

  test "no translation missing errors in production locale" do
    # Set up test to catch missing key fallbacks
    I18n.locale = :ja
    I18n.exception_handler = I18n::ExceptionHandler.new

    # Test critical keys
    critical_keys = %w[
      oroshi.onboarding.messages.step_completed
      oroshi.supplies.modals.action_scaffold.date_change
      oroshi.invoices.modal.mail_preview_title
      common.messages.access_denied
    ]

    critical_keys.each do |key|
      value = I18n.t(key, locale: :ja, default: nil)
      assert_not_nil value, "Key should exist in ja locale: #{key}"
      assert_not_includes value.to_s, "translation missing", "Key appears to be missing: #{key}"
    end
  end

  test "onboarding validation messages use correct i18n keys" do
    # Verify the structure of validation messages
    company_name_key = "oroshi.onboarding.steps.company_info.validations.company_name_required"
    postal_key = "oroshi.onboarding.steps.company_info.validations.postal_code_required"
    address_key = "oroshi.onboarding.steps.company_info.validations.address_required"
    missing_key = "oroshi.onboarding.steps.company_info.validations.required_fields_missing"

    company_msg = I18n.t(company_name_key)
    postal_msg = I18n.t(postal_key)
    address_msg = I18n.t(address_key)
    missing_msg = I18n.t(missing_key)

    assert_includes company_msg, "会社"
    assert_includes postal_msg, "郵便"
    assert_includes address_msg, "住所"
    assert_includes missing_msg, "必須"
  end

  test "mailer translations use proper Japanese" do
    greeting = I18n.t("mailers.invoices.greeting")
    description = I18n.t("mailers.invoices.description")
    closing = I18n.t("mailers.invoices.closing")

    # Check for common mailer patterns
    assert_includes greeting, "お世話"
    assert_includes description, "明細"
    assert_includes closing, "願"
  end

  test "modal titles are properly formatted" do
    modal_keys = %w[
      oroshi.supplies.modal.panel_title
      oroshi.orders.modal.panel_title
      oroshi.invoices.modal.mail_preview_title
    ]

    modal_keys.each do |key|
      value = I18n.t(key)
      # Title should be a string and contain meaningful Japanese text
      assert_kind_of String, value
      assert value.length > 1, "Modal title too short: #{key}"
    end
  end

  test "button translations are consistent across locales" do
    # Common buttons should have consistent usage
    close_button = I18n.t("common.buttons.close")
    save_button = I18n.t("common.buttons.save")
    delete_button = I18n.t("common.buttons.delete")

    assert_equal "閉じる", close_button
    assert_equal "保存", save_button
    assert_equal "削除", delete_button
  end

  test "supply dates pdf filename is properly formatted" do
    pdf_filename = I18n.t("oroshi.supply_dates.pdf.filename")
    assert_includes pdf_filename, "供給"
    assert_includes pdf_filename, "チェック"
  end

  test "message templates with interpolation work correctly" do
    # Test keys that use string interpolation
    supply_days_key = "oroshi.supplies.modals.action_scaffold.supply_days_count"
    message = I18n.t(supply_days_key, count: 5)
    assert_includes message, "5"
    assert_includes message, "日"

    # Test template_missing interpolation
    template_missing_key = "oroshi.onboarding.template_missing"
    message = I18n.t(template_missing_key, step: "company_info")
    assert_includes message, "company_info"
    assert_includes message, "テンプレート"
  end
end
