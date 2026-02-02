# frozen_string_literal: true

require "test_helper"

class I18nKeyPresenceTest < ActiveSupport::TestCase
  test "all modal titles have translations" do
    keys = %w[
      layouts.modals.title
      layouts.modals.content
      common.buttons.close
      oroshi.supplies.modal.panel_title
      oroshi.orders.modal.panel_title
      oroshi.invoices.modal.mail_preview_title
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all onboarding flash messages have translations" do
    keys = %w[
      oroshi.onboarding.messages.step_completed
      oroshi.onboarding.messages.complete
      oroshi.onboarding.messages.skipped
      oroshi.onboarding.messages.resuming
      oroshi.onboarding.messages.checklist_hidden
      oroshi.onboarding.messages.deleted
      oroshi.onboarding.messages.invalid_step
      oroshi.onboarding.messages.sign_in_required
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all company info validation messages have translations" do
    keys = %w[
      oroshi.onboarding.steps.company_info.validations.company_name_required
      oroshi.onboarding.steps.company_info.validations.postal_code_required
      oroshi.onboarding.steps.company_info.validations.address_required
      oroshi.onboarding.steps.company_info.validations.required_fields_missing
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all supply modal action messages have translations" do
    keys = %w[
      oroshi.supplies.modals.action_scaffold.date_change
      oroshi.supplies.modals.action_scaffold.no_supply
      oroshi.supplies.modals.action_scaffold.supply_days_count
      oroshi.supplies.modals.action_scaffold.cannot_reflect_no_supply
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all supply price action messages have translations" do
    keys = %w[
      oroshi.supplies.modals.price_actions.update_button
      oroshi.supplies.modals.price_actions.reflect_confirmation
      oroshi.supplies.modals.price_actions.cannot_reflect_no_supply
      oroshi.supplies.modals.price_actions.multi_select_help
      oroshi.supplies.modals.price_actions.remove_section_help
      oroshi.supplies.modals.price_actions.add_section_help
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all payment receipt dashboard messages have translations" do
    keys = %w[
      oroshi.payment_receipts.dashboard.no_outstanding_buyers
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all product variation form messages have translations" do
    keys = %w[
      oroshi.product_variations.form.select_container
      oroshi.product_variations.form.calculate_button
      oroshi.product_variations.form.show_cost_details
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all material categories messages have translations" do
    keys = %w[
      oroshi.material_categories.index.page_title
      oroshi.material_categories.index.no_records_warning
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all production zones messages have translations" do
    keys = %w[
      oroshi.production_zones.index.loading
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all supply dates messages have translations" do
    keys = %w[
      oroshi.supply_dates.pdf.filename
      oroshi.supply_dates.pdf.processing_message
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all supplies page messages have translations" do
    keys = %w[
      oroshi.supplies.index.page_title
      oroshi.supplies.index.loading
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all orders page messages have translations" do
    keys = %w[
      oroshi.orders.search.page_title
      oroshi.orders.modal.panel_title
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all invoice mailer messages have translations" do
    keys = %w[
      mailers.invoices.greeting
      mailers.invoices.description
      mailers.invoices.closing
      mailers.invoices.location_label
      mailers.invoices.file_label
      mailers.invoices.password_label
      oroshi.invoices.modal.attachments_label
      oroshi.invoices.modal.browser_notice
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all product position update messages have translations" do
    keys = %w[
      oroshi.products.messages.positions_updated
      oroshi.supply_type_variations.messages.positions_updated
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end

  test "all common message translations exist" do
    keys = %w[
      common.messages.access_denied
      common.messages.sign_in_required
    ]
    keys.each { |key| assert I18n.exists?(key), "Missing key: #{key}" }
  end
end
