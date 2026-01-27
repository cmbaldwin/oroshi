# frozen_string_literal: true

require "csv"
require "net/http"
require "openssl"
require "holiday_jp"

class Oroshi::SuppliesController < Oroshi::ApplicationController
  before_action :set_supply
  before_action :set_supply_dates, only: %i[index]

  # Authorization callbacks
  before_action :authorize_supply_index, only: %i[index]
  before_action :authorize_supply, only: %i[show update]
  before_action :authorize_supply_create, only: %i[create]

  # GET /oroshi/supplies
  # GET /oroshi/supplies.json
  def index; end

  # GET /oroshi/supplies/1
  def show; end

  # POST /oroshi/supplies
  def create
    @supply = Oroshi::Supply.new(supply_params)
    @supply.save
    head :ok
  end

  # PATCH/PUT /oroshi/supplies/1
  def update
    @supply.update(supply_params)
    head :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_supply
    id = params[:id] || params[:supply_id]
    @supply = id ? Oroshi::Supply.find(id) : Oroshi::Supply.new
  end

  def fetch_supply_range(start_date, end_date)
    offset = 14.days
    start_date = Date.strptime(start_date) if start_date
    start_date ||= Time.zone.today.at_beginning_of_month - offset
    end_date = Date.strptime(end_date) if end_date
    end_date ||= Time.zone.today.end_of_month + offset
    start_date..end_date
  end

  def set_supply_dates
    range = fetch_supply_range(calendar_params["start"], calendar_params["end"])
    @invoices = Oroshi::Invoice.where("start_date IN (?) OR end_date IN (?)", range, range)
    @supply_dates = Oroshi::SupplyDate
                    .includes(supply_date_supply_type_variations: { supply_type_variation: :supply_type })
                    .where(date: range)
    @holidays = japanese_holiday_background_events(range)
  end

  def calendar_params
    params.permit(:place, :start, :end, :_, :format)
  end

  # Only allow a list of trusted parameters through.
  def supply_params
    params.require(:oroshi_supply)
          .permit(:supply_date_id, :supply_type_variation_id, :supply_reception_time_id,
                  :supplier_id, :quantity, :price, :entry_index)
  end

  # Calendar helper methods for Japanese holidays and market holidays
  def japanese_holiday_background_events(range)
    Rails.cache.fetch("japanese_holiday_background_events_#{range.first}_#{range.last}", expires_in: 24.hours) do
      japanese_holidays = HolidayJp.between(range.first - 7.days, range.last + 7.days)
      ichiba_holidays = get_ichiba_holidays(range)

      events = japanese_holidays.each_with_object([]) do |holiday, memo|
        memo << {
          title: holiday.name,
          className: "bg-secondary bg-opacity-20",
          start: holiday.date,
          end: holiday.date,
          display: "background"
        }
      end

      events.concat(range.each_with_object([]) do |date, memo|
        if ichiba_holidays.include?(date)
          memo << {
            className: "bg-secondary bg-opacity-30",
            start: date,
            end: date,
            display: "background"
          }
        end
      end)
    end
  end

  def get_ichiba_holidays(range)
    first_year = extract_japanese_year(range.first.to_date.jisx0301)
    last_year  = extract_japanese_year(range.last.to_date.jisx0301)

    [ first_year, last_year ].uniq.each_with_object([]) do |year, memo|
      next unless year # Skip if year extraction failed

      url = "https://www.shijou.metro.tokyo.lg.jp/documents/d/shijou/#{year}suisancsv"
      csv_content = fetch_csv_content(url)

      begin
        CSV.parse(csv_content, headers: true, encoding: "Shift_JIS").each do |row|
          memo << Date.parse(row["Start Date"]) if row["Start Date"]
        end
      rescue CSV::MalformedCSVError => e
        logger.error "CSV parsing failed for #{url}: #{e.message}"
      rescue StandardError => e
        logger.error "Error processing CSV from #{url}: #{e.message}"
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

  # Pundit authorization methods
  def authorize_supply
    authorize @supply
  end

  def authorize_supply_create
    authorize Oroshi::Supply, :create?
  end

  def authorize_supply_index
    authorize Oroshi::Supply, :index?
  end
end
