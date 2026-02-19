# frozen_string_literal: true

require "test_helper"

class Oroshi::ExportJobTest < ActiveJob::TestCase
  setup do
    @message = create(:message)
    @order = create(:oroshi_order, shipping_date: Time.zone.today)
  end

  test "generates CSV export and attaches to message" do
    Oroshi::ExportJob.perform_now(
      "Exports::OrdersExport",
      "csv",
      @message.id,
      { "date" => Time.zone.today.to_s }
    )

    @message.reload
    assert_equal true, @message.state
    assert @message.stored_file.attached?
    assert @message.stored_file.filename.to_s.end_with?(".csv")
  end

  test "generates XLSX export and attaches to message" do
    Oroshi::ExportJob.perform_now(
      "Exports::OrdersExport",
      "xlsx",
      @message.id,
      { "date" => Time.zone.today.to_s }
    )

    @message.reload
    assert_equal true, @message.state
    assert @message.stored_file.attached?
    assert @message.stored_file.filename.to_s.end_with?(".xlsx")
  end

  test "generates JSON export and attaches to message" do
    Oroshi::ExportJob.perform_now(
      "Exports::OrdersExport",
      "json",
      @message.id,
      { "date" => Time.zone.today.to_s }
    )

    @message.reload
    assert_equal true, @message.state
    assert @message.stored_file.attached?
    assert @message.stored_file.filename.to_s.end_with?(".json")
  end

  test "generates PDF export and attaches to message" do
    Oroshi::ExportJob.perform_now(
      "Exports::OrdersExport",
      "pdf",
      @message.id,
      { "date" => Time.zone.today.to_s }
    )

    @message.reload
    assert_equal true, @message.state
    assert @message.stored_file.attached?
    assert @message.stored_file.filename.to_s.end_with?(".pdf")
  end

  test "sets completed message on success" do
    Oroshi::ExportJob.perform_now(
      "Exports::OrdersExport",
      "csv",
      @message.id,
      { "date" => Time.zone.today.to_s }
    )

    @message.reload
    assert_equal I18n.t("oroshi.exports.completed"), @message.message
  end

  test "sets failure state on error" do
    assert_raises(NameError) do
      Oroshi::ExportJob.perform_now(
        "Exports::NonexistentExport",
        "csv",
        @message.id,
        {}
      )
    end

    @message.reload
    assert_equal false, @message.state
  end

  test "works with all export types" do
    export_types = %w[
      Exports::OrdersExport
      Exports::RevenueExport
      Exports::InventoryExport
      Exports::ShippingExport
    ]

    export_types.each do |export_class|
      message = create(:message)
      Oroshi::ExportJob.perform_now(
        export_class,
        "csv",
        message.id,
        { "date" => Time.zone.today.to_s }
      )

      message.reload
      assert_equal true, message.state, "#{export_class} CSV export failed"
    end
  end
end
