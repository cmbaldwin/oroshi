# frozen_string_literal: true

require "csv"

class ApplicationController < ActionController::Base
  include Oroshi::UrlHelper

  protect_from_forgery with: :exception

  # Conditionally add Devise authentication if available
  before_action :maybe_authenticate_user
  before_action :check_user
  before_action :check_onboarding
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :set_access_control_headers

  before_action :set_locale

  # Wrapper method to handle Devise authentication gracefully
  def maybe_authenticate_user
    authenticate_user! if defined?(Devise)
  rescue NoMethodError => e
    # Devise not available or authenticate_user! not defined - skip authentication
    Rails.logger.debug "Skipping authentication: #{e.message}" if Rails.env.development?
  end

  def check_user
    return unless respond_to?(:current_user)
    return unless current_user
    return if current_user.approved?
    return unless current_user.user? || current_user.employee?

    authentication_notice
  end

  def check_admin
    return unless respond_to?(:current_user) && current_user
    return if current_user.admin?

    authentication_notice
  end

  def check_onboarding
    return unless respond_to?(:current_user)
    return unless current_user
    return if respond_to?(:devise_controller?) && devise_controller?
    return if controller_path == "oroshi/onboarding"

    progress = current_user.onboarding_progress || current_user.create_onboarding_progress!

    return if progress.completed? || progress.skipped?

    redirect_to oroshi_onboarding_index_path
  end

  def check_vip
    return unless respond_to?(:current_user) && current_user
    return if current_user.admin? || current_user.vip?

    authentication_notice
  end

  def authentication_notice
    flash[:notice] = t("common.messages.access_denied")
    redirect_to root_path, error: t("common.messages.access_denied")
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
    Carmen.i18n_backend.locale = params[:locale]&.to_sym || I18n.default_locale
  end

  def set_access_control_headers
    return unless Rails.env.test?

    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "POST, PUT, DELETE, GET, OPTIONS"
    headers["Access-Control-Request-Method"] = "*"
    headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept, Authorization"
  end

  def japanese_holiday_background_events(range)
    Rails.cache.fetch("japanese_holiday_background_events_#{range}") do
      japanese_holidays = HolidayJp.between(range.first - 7.days, range.last + 7.days)
      ichiba_holidays = get_ichiba_holidays(range)
      events = japanese_holidays.each_with_object([]) do |holiday, memo|
        memo << { title: holiday.name, className: "bg-secondary bg-opacity-20",
                  start: holiday.date, end: holiday.date, display: "background" }
      end
      events.concat(range.each_with_object([]) do |date, memo|
                      if ichiba_holidays.include?(date)
                        memo << { className: "bg-secondary bg-opacity-30", start: date, end: date,
                                  display: "background" }
                      end
                    end)
    end
  end

  def get_ichiba_holidays(range)
    first_year = extract_japanese_year(range.first.to_date.jisx0301)
    last_year  = extract_japanese_year(range.last.to_date.jisx0301)
    [ first_year, last_year ].uniq.each_with_object([]) do |year, memo|
      url = "https://www.shijou.metro.tokyo.lg.jp/documents/d/shijou/#{year}suisancsv"
      csv_content = fetch_csv_content(url)
      begin
        CSV.parse(csv_content, headers: true, encoding: "Shift_JIS").each do |row|
          memo << Date.parse(row["Start Date"])
        end
      rescue CSV::MalformedCSVError => e
        logger.error "CSV parsing failed for #{url}: #{e.message}"
      end
    end
  end

  def fetch_csv_content(url)
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    http.read_timeout = 10
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.cert_store = OpenSSL::X509::Store.new
    http.cert_store.set_default_paths

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      response.body
    else
      logger.error "Failed to fetch CSV content from #{url}: #{response.code} #{response.message}"
      ""
    end
  rescue OpenSSL::SSL::SSLError => e
    logger.error "SSL error fetching CSV content from #{url}: #{e.message}"
    ""
  rescue StandardError => e
    logger.error "Error fetching CSV content from #{url}: #{e.message}"
    ""
  end

  def extract_japanese_year(date_str)
    match = date_str.match(/^[A-Z]+(\d+)\./)
    match[1] if match
  end

  protected

  def configure_permitted_parameters
    added_attrs = %i[username email password password_confirmation remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end
end
