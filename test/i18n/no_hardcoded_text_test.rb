# frozen_string_literal: true

require "test_helper"

class I18nNoHardcodedTextTest < ActiveSupport::TestCase
  test "onboarding_controller has no hardcoded English strings" do
    content = File.read(Oroshi::Engine.root.join("app/controllers/oroshi/onboarding_controller.rb"))
    assert_not_includes content, "Step completed!"
    assert_not_includes content, "Onboarding complete!"
    assert_not_includes content, "Onboarding skipped"
    assert_not_includes content, "Resuming onboarding"
    assert_not_includes content, "Invalid step"
    assert_not_includes content, "Please sign in to continue."
  end

  test "onboarding_controller has no hardcoded Japanese strings in messages" do
    content = File.read(Oroshi::Engine.root.join("app/controllers/oroshi/onboarding_controller.rb"))
    assert_not_includes content, "削除しました"
    assert_not_includes content, "チェックリストを非表示にしました"
  end

  test "onboarding_controller company_info validation uses i18n" do
    content = File.read(Oroshi::Engine.root.join("app/controllers/oroshi/onboarding_controller.rb"))
    # These should be replaced with t() calls
    assert_not_includes content, "会社名は必須です"
    assert_not_includes content, "郵便番号は必須です"
    assert_not_includes content, "住所は必須です"
    assert_not_includes content, "必須項目が入力されていません"
  end

  test "application_controller has no Unicode escape workarounds" do
    content = File.read(Oroshi::Engine.root.join("app/controllers/oroshi/application_controller.rb"))
    assert_not_includes content, "\\u305D\\u306E"  # Unicode escape pattern
  end

  test "products_controller uses i18n for position update message" do
    content = File.read(Oroshi::Engine.root.join("app/controllers/oroshi/products_controller.rb"))
    assert_not_includes content, "\"Positions updated successfully\""
  end

  test "supply_type_variations_controller uses i18n for position update message" do
    content = File.read(Oroshi::Engine.root.join("app/controllers/oroshi/supply_type_variations_controller.rb"))
    assert_not_includes content, "\"Positions updated successfully\""
  end

  test "supply_dates_controller uses i18n for messages" do
    content = File.read(Oroshi::Engine.root.join("app/controllers/oroshi/supply_dates_controller.rb"))
    assert_not_includes content, "供給チェック表 "
    assert_not_includes content, "供給受入れチェック表を作成中"
  end

  test "payment_receipts quick_entry view uses i18n" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/payment_receipts/dashboard/quick_entry.html.erb"))
    assert_not_includes content, "未払いの買い手がいません"
  end

  test "shared modal view uses i18n for all text" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/shared/_modal.html.erb"))
    assert_not_includes content, "タイトル"
    assert_not_includes content, "内容はこちら"
    assert_not_includes content, "閉じる"
  end

  test "supplies modal init uses i18n for titles and buttons" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/supplies/modal/_init_supply_modal.html.erb"))
    assert_not_includes content, "供給ツールパネル"
  end

  test "supplies action_scaffold uses i18n" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/supplies/modal/shared/_action_scaffold.html.erb"))
    assert_not_includes content, "日付変更"
    assert_not_includes content, "供給なし"
    assert_not_includes content, "選択した日付の範囲内の供給ある日"
    assert_not_includes content, "供給なしので、反映できません"
  end

  test "orders modal uses i18n" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/orders/modal/_order_modal.html.erb"))
    assert_not_includes content, "注文ツールパネル"
  end

  test "invoices modal preview uses i18n" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/invoices/modal/_mail_notification_preview.html.erb"))
    assert_not_includes content, "メールのプレビュー"
    assert_not_includes content, "添付ファイル:"
    assert_not_includes content, "注意:"
  end

  test "material_categories index uses i18n" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/material_categories/index.html.erb"))
    assert_not_includes content, "製造材料カテゴリー"
    assert_not_includes content, "製造材料カテゴリが登録されていません"
  end

  test "production_zones index uses i18n for loading text" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/production_zones/index.html.erb"))
    assert_not_includes content, "読み込み中..."
  end

  test "invoice mailer uses i18n" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/invoices/mailer/invoice_notification.html.erb"))
    assert_not_includes content, "いつもお世話になっております"
    assert_not_includes content, "支払い明細書を送付"
    assert_not_includes content, "宜しくお願い致します"
    assert_not_includes content, "場所"
    assert_not_includes content, "ファイル"
    assert_not_includes content, "パスワード"
  end

  test "onboarding show uses i18n for missing template placeholder" do
    content = File.read(Oroshi::Engine.root.join("app/views/oroshi/onboarding/show.html.erb"))
    assert_not_includes content, "Coming soon"
  end
end
