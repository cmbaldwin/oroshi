# frozen_string_literal: true

module ApplicationHelper
  # Company settings helper
  def company_setting(key, default_value = nil)
    company_settings = Rails.cache.fetch("oroshi_company_settings", expires_in: 1.hour) do
      Setting.find_by(name: "oroshi_company_settings")&.settings
    end
    company_settings&.dig(key) || default_value
  end

  def company_info
    {
      name: company_setting("name", "株式会社サンプル商店"),
      postal_code: company_setting("postal_code", "100-0001"),
      address: company_setting("address", "東京都千代田区千代田1-1"),
      phone: company_setting("phone", "03-0000-0000"),
      fax: company_setting("fax", "03-0000-0001"),
      mail: company_setting("mail", "info@example.com"),
      web: company_setting("web", "https://example.com")
    }
  end

  def get_setting(settings, setting_name)
    settings&.safe_settings&.dig(setting_name)
  end

  def get_masked_setting(settings, setting_name)
    settings&.masked_setting(setting_name)
  end

  def has_credential?(settings, setting_name)
    settings&.setting?(setting_name)
  end

  def create_chart(chart_params)
    method(chart_params[:chart_type]).call method("#{chart_params[:chart_path]}_path").call,
                                           **chart_params[:init_params]
  end

  def title(page_title)
    content_for(:title) { page_title }
  end

  # Japanese date/time formatting helpers
  def weekday_japanese(num)
    weekdays = { 0 => "日", 1 => "月", 2 => "火", 3 => "水", 4 => "木", 5 => "金", 6 => "土" }
    weekdays[num]
  end

  def to_nengapi(date)
    date&.strftime("%Y年%m月%d日")
  end

  def to_gapi(date)
    date&.strftime("%m月%d日")
  end

  def to_nengapiyoubi(date)
    date&.strftime("%Y年%m月%d日 (#{weekday_japanese(date.wday)})")
  end

  def to_gapiyoubi(date)
    date&.strftime("%m月%d日 (#{weekday_japanese(date.wday)})")
  end

  def to_nengapijibun(date)
    date&.strftime("%Y年%m月%d日%H時%M分")
  end

  def to_jibun(date)
    date&.strftime("%H時%M分")
  end

  # Currency helpers
  def yenify(number)
    ActionController::Base.helpers.number_to_currency(number, locale: :ja, unit: "")
  end

  def yenify_with_decimal(number)
    ActionController::Base.helpers.number_to_currency(number, locale: :ja, unit: "", precision: 1)
  end

  # UI helpers
  def cycle_table_rows
    cycle("even", "odd")
  end

  def nengapi_today
    Time.zone.today.strftime("%Y年%m月%d日")
  end

  def nengapi_today_plus(number)
    (Time.zone.today + number).strftime("%Y年%m月%d日")
  end

  def icon(icon, options = {})
    classes = "bi bi-#{icon}"
    classes += " #{options[:class]}" if options[:class].present?
    style = ""
    if options[:size].present?
      style = "font-size: #{options[:size]}px; width: #{options[:size]}px; height: #{options[:size]}px;"
    end
    "<i class='#{classes}' style='#{style}'></i>".html_safe
  end
end
