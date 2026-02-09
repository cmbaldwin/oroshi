# frozen_string_literal: true

require 'holiday_jp'
require 'csv'
require 'net/http'
require 'openssl'

module Oroshi
  module CalendarHelpers
    extend ActiveSupport::Concern

    # Generates Japanese holiday and market holiday background events for FullCalendar
    # @param range [Range<Date>] Date range to generate events for
    # @return [Array<Hash>] Array of FullCalendar event objects
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

    private

    # Fetches market (ichiba) holidays from Tokyo Metropolitan Central Wholesale Market
    # @param range [Range<Date>] Date range to fetch holidays for
    # @return [Array<Date>] Array of market holiday dates
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

    # Fetches CSV content from a URL with SSL verification
    # @param url [String] URL to fetch CSV from
    # @return [String] CSV content or empty string on error
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

    # Extracts the year number from a Japanese era date string (e.g., "R06.01.01" -> "06")
    # @param date_str [String] Japanese era date string
    # @return [String, nil] Year number or nil if extraction fails
    def extract_japanese_year(date_str)
      match = date_str.match(/^[A-Z]+(\d+)\./)
      match[1] if match
    end
  end
end
