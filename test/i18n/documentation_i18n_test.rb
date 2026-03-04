# frozen_string_literal: true

require "test_helper"

class DocumentationI18nTest < ActiveSupport::TestCase
  DOCUMENTATION_SECTIONS = Oroshi::DocumentationController::SECTIONS

  # === Chrome Keys ===

  test "documentation chrome keys exist in both locales" do
    chrome_keys = %w[title home overview search_placeholder see_also help_tooltip]

    chrome_keys.each do |key|
      full_key = "oroshi.documentation.chrome.#{key}"
      %i[ja en].each do |locale|
        value = I18n.t(full_key, locale: locale, raise: true)
        assert value.present?, "Missing translation: #{full_key} in #{locale}"
      end
    end
  end

  # === Section Names ===

  test "all section names have translations in both locales" do
    DOCUMENTATION_SECTIONS.each_key do |section|
      %i[ja en].each do |locale|
        key = "oroshi.documentation.sections.#{section}"
        value = I18n.t(key, locale: locale, raise: true)
        assert value.present?, "Missing section name: #{key} in #{locale}"
      end
    end
  end

  # === Section Descriptions ===

  test "all section descriptions have translations in both locales" do
    DOCUMENTATION_SECTIONS.each_key do |section|
      %i[ja en].each do |locale|
        key = "oroshi.documentation.section_descriptions.#{section}"
        value = I18n.t(key, locale: locale, raise: true)
        assert value.present?, "Missing section description: #{key} in #{locale}"
      end
    end
  end

  # === Page Names ===

  test "all page names have translations in both locales" do
    DOCUMENTATION_SECTIONS.each do |section, pages|
      pages.each do |page|
        %i[ja en].each do |locale|
          key = "oroshi.documentation.pages.#{section}.#{page}"
          value = I18n.t(key, locale: locale, raise: true)
          assert value.present?, "Missing page name: #{key} in #{locale}"
        end
      end
    end
  end

  # === Message Keys ===

  test "documentation message keys exist in both locales" do
    %w[invalid_section invalid_page].each do |msg|
      %i[ja en].each do |locale|
        key = "oroshi.documentation.messages.#{msg}"
        value = I18n.t(key, locale: locale, raise: true)
        assert value.present?, "Missing message: #{key} in #{locale}"
      end
    end
  end

  # === Content Keys Symmetry ===

  test "Japanese documentation keys have English equivalents" do
    ja_keys = collect_leaf_keys(I18n.t("oroshi.documentation", locale: :ja), "oroshi.documentation")
    en_keys = collect_leaf_keys(I18n.t("oroshi.documentation", locale: :en), "oroshi.documentation")

    missing_in_en = ja_keys - en_keys
    assert missing_in_en.empty?, "Keys in JA but missing in EN:\n#{missing_in_en.join("\n")}"
  end

  test "English documentation keys have Japanese equivalents" do
    ja_keys = collect_leaf_keys(I18n.t("oroshi.documentation", locale: :ja), "oroshi.documentation")
    en_keys = collect_leaf_keys(I18n.t("oroshi.documentation", locale: :en), "oroshi.documentation")

    missing_in_ja = en_keys - ja_keys
    assert missing_in_ja.empty?, "Keys in EN but missing in JA:\n#{missing_in_ja.join("\n")}"
  end

  # === Japanese Content Quality ===

  test "Japanese section names contain kanji or kana" do
    DOCUMENTATION_SECTIONS.each_key do |section|
      value = I18n.t("oroshi.documentation.sections.#{section}", locale: :ja)
      assert value.match?(/[\p{Han}\p{Hiragana}\p{Katakana}]/), "Japanese section name '#{section}' has no Japanese characters: #{value}"
    end
  end

  test "Japanese page names contain kanji or kana" do
    DOCUMENTATION_SECTIONS.each do |section, pages|
      pages.each do |page|
        value = I18n.t("oroshi.documentation.pages.#{section}.#{page}", locale: :ja)
        assert value.match?(/[\p{Han}\p{Hiragana}\p{Katakana}]/), "Japanese page name '#{section}/#{page}' has no Japanese characters: #{value}"
      end
    end
  end

  private

  def collect_leaf_keys(hash, prefix = "")
    keys = []
    hash.each do |key, value|
      full_key = prefix.present? ? "#{prefix}.#{key}" : key.to_s
      if value.is_a?(Hash)
        keys.concat(collect_leaf_keys(value, full_key))
      else
        keys << full_key
      end
    end
    keys
  end
end
