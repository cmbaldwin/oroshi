# frozen_string_literal: true

require "test_helper"

class Oroshi::ExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  test "creates export for valid params" do
    assert_enqueued_with(job: Oroshi::ExportJob) do
      post oroshi_exports_path, params: {
        export_type: "orders",
        format_type: "csv",
        date: Time.zone.today.to_s
      }
    end

    assert_response :ok
  end

  test "rejects invalid export_type" do
    post oroshi_exports_path, params: {
      export_type: "invalid",
      format_type: "csv"
    }

    assert_response :unprocessable_entity
  end

  test "rejects invalid format_type" do
    post oroshi_exports_path, params: {
      export_type: "orders",
      format_type: "xml"
    }

    assert_response :unprocessable_entity
  end

  test "creates message record with correct attributes" do
    assert_difference("Message.count", 1) do
      post oroshi_exports_path, params: {
        export_type: "revenue",
        format_type: "xlsx",
        date: Time.zone.today.to_s
      }
    end

    message = Message.last
    assert_nil message.state
    assert_equal I18n.t("oroshi.exports.processing"), message.message
    assert_equal "revenue", message.data["export_type"]
    assert_equal "xlsx", message.data["format"]
  end

  test "passes filter params to export job" do
    buyer = create(:oroshi_buyer)

    assert_enqueued_with(job: Oroshi::ExportJob) do
      post oroshi_exports_path, params: {
        export_type: "orders",
        format_type: "csv",
        date: Time.zone.today.to_s,
        buyer_ids: [buyer.id.to_s]
      }
    end

    assert_response :ok
  end

  test "supports date range params" do
    assert_enqueued_with(job: Oroshi::ExportJob) do
      post oroshi_exports_path, params: {
        export_type: "orders",
        format_type: "csv",
        start_date: 1.month.ago.to_date.to_s,
        end_date: Time.zone.today.to_s
      }
    end

    assert_response :ok
  end

  test "all export types are accepted" do
    %w[orders revenue production inventory supply shipping].each do |export_type|
      post oroshi_exports_path, params: {
        export_type: export_type,
        format_type: "csv",
        date: Time.zone.today.to_s
      }

      assert_response :ok, "Export type '#{export_type}' should be accepted"
    end
  end

  test "all format types are accepted" do
    %w[csv xlsx pdf json].each do |format_type|
      post oroshi_exports_path, params: {
        export_type: "orders",
        format_type: format_type,
        date: Time.zone.today.to_s
      }

      assert_response :ok, "Format '#{format_type}' should be accepted"
    end
  end

  test "requires authentication" do
    sign_out @user
    post oroshi_exports_path, params: {
      export_type: "orders",
      format_type: "csv"
    }

    assert_response :redirect
  end

  test "supplier role is denied export access" do
    supplier_user = create(:user, :supplier)
    sign_in supplier_user

    assert_raises(Pundit::NotAuthorizedError) do
      post oroshi_exports_path, params: {
        export_type: "orders",
        format_type: "csv",
        date: Time.zone.today.to_s
      }
    end
  end
end
