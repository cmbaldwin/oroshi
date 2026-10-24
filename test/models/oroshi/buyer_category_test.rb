# frozen_string_literal: true

require "test_helper"

class Oroshi::BuyerCategoryTest < ActiveSupport::TestCase
  def setup
    @buyer_category = build(:oroshi_buyer_category)
  end

  # --- Validity ---

  test "is valid with valid attributes" do
    assert @buyer_category.valid?
  end

  # --- Validations ---

  test "is not valid without a name" do
    @buyer_category.name = nil
    assert_not @buyer_category.valid?
    assert_includes @buyer_category.errors[:name], I18n.t("errors.messages.blank")
  end

  test "is not valid without a symbol" do
    @buyer_category.symbol = nil
    assert_not @buyer_category.valid?
    assert_includes @buyer_category.errors[:symbol], I18n.t("errors.messages.blank")
  end

  test "is not valid without a color" do
    @buyer_category.color = nil
    assert_not @buyer_category.valid?
    assert_includes @buyer_category.errors[:color], I18n.t("errors.messages.blank")
  end

  # --- Scopes ---

  test "default scope orders by created_at ascending" do
    older = create(:oroshi_buyer_category, created_at: 2.days.ago)
    newer = create(:oroshi_buyer_category, created_at: 1.day.ago)

    results = Oroshi::BuyerCategory.all
    # The default scope orders by created_at, so older should come first
    older_index = results.index(older)
    newer_index = results.index(newer)
    assert older_index < newer_index, "Older category should appear before newer category"
  end

  # --- Associations ---

  test "has many buyers through buyer_buyer_categories" do
    assert_respond_to @buyer_category, :buyers
    assert_respond_to @buyer_category, :buyer_buyer_categories
  end

  test "can be persisted with valid attributes" do
    assert_difference "Oroshi::BuyerCategory.count", 1 do
      create(:oroshi_buyer_category)
    end
  end
end
