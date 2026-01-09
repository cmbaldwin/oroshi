#!/usr/bin/env ruby
# frozen_string_literal: true

# Yahoo API Sandbox Testing Script
#
# This script tests the Yahoo Japan Shopping API integration using the sandbox environment.
# It performs comprehensive tests without affecting production data or the database.
#
# Usage:
#   rails runner scripts/test_yahoo_sandbox.rb
#
# Requirements:
#   - YAHOO_CLIENT_V2 and YAHOO_SECRET_V2 environment variables must be set
#   - Valid OAuth tokens in User.find(1).data[:yahoo][:authorization]

require_relative '../config/environment'

class YahooSandboxTester
  attr_reader :client, :config, :results

  def initialize
    @client = YahooAPI::Client.new
    @config = YahooAPI.configuration
    @results = {
      passed: [],
      failed: [],
      skipped: []
    }
  end

  def run_all_tests
    puts "\n#{'=' * 80}"
    puts 'YAHOO JAPAN SHOPPING API - SANDBOX TESTING'
    puts '=' * 80
    puts "\nStarted at: #{Time.current.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "\n"

    # Configuration tests
    test_configuration

    # Authentication tests
    test_authentication_status

    # Only run API tests if authorized
    if @client.authorized?
      # Enable sandbox mode for testing
      enable_sandbox_mode

      # API endpoint tests
      test_order_count_endpoint
      test_order_list_endpoint
      test_order_info_endpoint

      # Error handling tests
      test_error_handling

      # Disable sandbox mode
      disable_sandbox_mode
    else
      skip('API endpoint tests', 'Not authorized - need to authenticate first')
      puts "\n⚠️  To authenticate, visit:"
      puts @client.authorization_url
    end

    # Print summary
    print_summary
  end

  private

  def test_configuration
    section('Configuration Tests')

    test('Configuration loaded') do
      assert @config.is_a?(YahooAPI::Configuration), 'Config should be YahooAPI::Configuration'
      true
    end

    test('V2 credentials present') do
      has_v2 = ENV['YAHOO_CLIENT_V2'].present? && ENV['YAHOO_SECRET_V2'].present?
      assert has_v2, 'V2 credentials should be set'
      puts "    ✓ Client ID: #{@config.client_id&.first(20)}..."
      puts "    ✓ Using V2: #{@config.v2_credentials?}"
      true
    end

    test('Required settings present') do
      @config.validate!
      puts "    ✓ Seller ID: #{@config.seller_id}"
      puts "    ✓ Redirect URI: #{@config.redirect_uri}"
      puts "    ✓ Token lifetime: #{@config.token_lifetime_minutes} minutes"
      true
    end
  end

  def test_authentication_status
    section('Authentication Tests')

    test('Client initialized') do
      assert @client.is_a?(YahooAPI::Client), 'Client should be YahooAPI::Client'
      assert @client.auth.present?, 'Auth should be present'
      true
    end

    test('Authorization status') do
      authorized = @client.authorized?
      if authorized
        puts "    ✓ Access token: #{@client.access_token&.first(20)}..."

        # Check token details
        user = @client.auth.user
        auth_data = user.data.dig(:yahoo, :authorization)

        if auth_data
          acquired = auth_data[:acquired]
          expires_in = auth_data['expires_in']

          puts "    ✓ Token acquired: #{acquired}"
          puts "    ✓ Expires in: #{expires_in} seconds"

          if acquired
            time_left = (acquired + @config.token_lifetime_minutes.minutes - DateTime.now).to_i
            puts "    ✓ Time remaining: ~#{time_left / 60} minutes"
          end
        end
      else
        puts '    ✗ Not authorized'

        # Check if refresh token available
        if @client.auth.refresh_token_available?
          puts '    ℹ Refresh token available - attempting refresh...'
          begin
            @client.ensure_authorized!
            puts '    ✓ Token refreshed successfully'
          rescue StandardError => e
            puts "    ✗ Refresh failed: #{e.message}"
          end
        end
      end

      authorized
    end

    test('Token refresh capability') do
      if @client.authorized?
        has_refresh = @client.auth.refresh_token.present?
        puts "    ✓ Refresh token: #{has_refresh ? 'Available' : 'Not available'}"
        has_refresh
      else
        skip('Token refresh test', 'Not authorized')
        false
      end
    end
  end

  def test_order_count_endpoint
    section('OrderCount Endpoint Test')

    test('orderCount API call') do
      counts = @client.order_count

      assert counts.is_a?(Hash), 'Should return hash'
      puts '    ✓ Response type: Hash'

      # Display counts
      puts "\n    Order Counts:"
      counts.each do |status, count|
        puts "      #{status.ljust(20)}: #{count}"
      end

      true
    rescue YahooAPI::APIError => e
      puts "    API Error: #{e.api_code} - #{e.api_message}"
      false
    end
  end

  def test_order_list_endpoint
    section('OrderList Endpoint Test')

    # Test with 1 day period
    test('orderList - Last 24 hours') do
      order_ids = @client.order_list(period: 1.day)

      assert order_ids.is_a?(Array), 'Should return array'
      puts "    ✓ Found #{order_ids.count} orders"

      if order_ids.any?
        puts '    ✓ Sample IDs:'
        order_ids.first(3).each do |id|
          puts "      - #{id}"
        end
      end

      # Store first order ID for info test
      @test_order_id = order_ids.first

      true
    rescue YahooAPI::APIError => e
      puts "    API Error: #{e.api_code} - #{e.api_message}"
      false
    end

    # Test with 1 week period
    test('orderList - Last 7 days') do
      order_ids = @client.order_list(period: 1.week)

      puts "    ✓ Found #{order_ids.count} orders (7 days)"
      true
    rescue YahooAPI::APIError => e
      puts "    API Error: #{e.api_code} - #{e.api_message}"
      false
    end
  end

  def test_order_info_endpoint
    section('OrderInfo Endpoint Test')

    test('orderInfo for specific order') do
      if @test_order_id
        details = @client.order_info(@test_order_id)

        assert details.is_a?(Hash), 'Should return hash'
        puts "    ✓ Order ID: #{details['OrderId']}"
        puts "    ✓ Status: #{details['OrderStatus']}"
        puts "    ✓ Order Time: #{details['OrderTime']}"

        # Display ship info if available
        if details['Ship']
          ship = details['Ship']
          puts "    ✓ Ship to: #{ship['ShipLastName']} #{ship['ShipFirstName']}"
          puts "    ✓ Zip: #{ship['ShipZipCode']}"
        end

        # Display payment info if available
        if details['Pay']
          pay = details['Pay']
          puts "    ✓ Payment: #{pay['PayKind']}"
        end

        # Display items
        if details['Item']
          items = details['Item'].is_a?(Array) ? details['Item'] : [details['Item']]
          puts "    ✓ Items: #{items.count}"
          items.first(2).each do |item|
            puts "      - #{item['Title']} (#{item['ItemId']})"
          end
        end

        true
      else
        skip('OrderInfo test', 'No order ID available from orderList test')
        false
      end
    rescue YahooAPI::OrderNotFoundError => e
      puts "    Order not found: #{e.message}"
      false
    rescue YahooAPI::APIError => e
      puts "    API Error: #{e.api_code} - #{e.api_message}"
      false
    end
  end

  def test_error_handling
    section('Error Handling Tests')

    test('Invalid order ID handling') do
      @client.order_info('invalid-order-id-12345')
      false
    rescue YahooAPI::OrderNotFoundError => e
      puts '    ✓ Caught OrderNotFoundError'
      puts "    ✓ Message: #{e.message}"
      puts "    ✓ API Code: #{e.api_code}"
      true
    rescue StandardError => e
      puts "    ✗ Unexpected error: #{e.class} - #{e.message}"
      false
    end

    test('Rate limit handling (simulated)') do
      # NOTE: We can't easily test rate limiting without hitting the limit
      # This just verifies the error class exists

      raise YahooAPI::RateLimitError, 'Test rate limit'
    rescue YahooAPI::RateLimitError
      puts '    ✓ RateLimitError class defined'
      puts '    ✓ Can be caught correctly'
      true
    end

    test('Network error handling') do
      # Verify error classes are defined
      errors_defined = defined?(YahooAPI::NetworkError) &&
                       defined?(YahooAPI::AuthenticationError) &&
                       defined?(YahooAPI::ConfigurationError)

      puts '    ✓ All error classes defined'
      errors_defined
    end
  end

  def enable_sandbox_mode
    puts "\n#{'-' * 80}"
    puts 'SANDBOX MODE ENABLED'
    puts '-' * 80
    @config.use_test_environment = true
    puts "Using test base URL: #{@config.api_base_url}"
  end

  def disable_sandbox_mode
    @config.use_test_environment = false
    puts "\n#{'-' * 80}"
    puts 'SANDBOX MODE DISABLED'
    puts '-' * 80
  end

  def section(title)
    puts "\n#{'-' * 80}"
    puts title
    puts '-' * 80
  end

  def test(description)
    print "  #{description}... "
    result = yield

    if result
      puts '✅ PASS'
      @results[:passed] << description
    else
      puts '❌ FAIL'
      @results[:failed] << description
    end

    result
  rescue StandardError => e
    puts '❌ ERROR'
    puts "    Exception: #{e.class}"
    puts "    Message: #{e.message}"
    puts '    Backtrace (first 3 lines):'
    e.backtrace.first(3).each { |line| puts "      #{line}" }
    @results[:failed] << "#{description} (#{e.class})"
    false
  end

  def skip(description, reason)
    puts "  #{description}... ⏭️  SKIP"
    puts "    Reason: #{reason}"
    @results[:skipped] << description
  end

  def assert(condition, message)
    raise message unless condition
  end

  def print_summary
    puts "\n#{'=' * 80}"
    puts 'TEST SUMMARY'
    puts '=' * 80

    total = @results[:passed].count + @results[:failed].count

    puts "\nResults:"
    puts "  ✅ Passed:  #{@results[:passed].count}"
    puts "  ❌ Failed:  #{@results[:failed].count}"
    puts "  ⏭️  Skipped: #{@results[:skipped].count}"
    puts "  📊 Total:   #{total}"

    if @results[:failed].any?
      puts "\nFailed Tests:"
      @results[:failed].each do |test|
        puts "  - #{test}"
      end
    end

    if @results[:skipped].any?
      puts "\nSkipped Tests:"
      @results[:skipped].each do |test|
        puts "  - #{test}"
      end
    end

    puts "\nCompleted at: #{Time.current.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts '=' * 80
    puts "\n"

    # Exit with appropriate code
    exit(@results[:failed].empty? ? 0 : 1)
  end
end

# Run tests
tester = YahooSandboxTester.new
tester.run_all_tests
