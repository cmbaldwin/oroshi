#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick Yahoo API Authentication Test
#
# This script performs a quick check of the Yahoo API authentication status
# and basic connectivity without modifying any data.
#
# Usage:
#   rails runner scripts/test_yahoo_auth.rb

require_relative '../config/environment'

puts "\n" + ('=' * 80)
puts 'YAHOO API - QUICK AUTH TEST'
puts '=' * 80
puts "\n"

# Skip user init to avoid encrypted data issues in development
client = YahooAPI::Client.new(skip_user_init: true)
config = YahooAPI.configuration

# Configuration check
puts 'Configuration:'
puts "  Client ID: #{config.client_id&.first(20)}..."
puts "  Using V2: #{config.v2_credentials?}"
puts "  Using Legacy: #{config.using_legacy_credentials?}"
puts "  Seller ID: #{config.seller_id}"
puts "  Redirect URI: #{config.redirect_uri}"
puts "\n"

# Authorization status
puts 'Authorization Status:'
authorized = client.authorized?
puts "  Authorized: #{authorized ? '✅ YES' : '❌ NO'}"

if authorized
  # Show token details
  user = client.auth.user
  auth_data = user.data.dig(:yahoo, :authorization)

  if auth_data
    puts "  Access Token: #{client.access_token&.first(30)}..."
    puts "  Acquired: #{auth_data[:acquired]}"
    puts "  Expires In: #{auth_data['expires_in']} seconds"

    if auth_data[:acquired]
      time_left = (auth_data[:acquired] + config.token_lifetime_minutes.minutes - DateTime.now).to_i
      puts "  Time Remaining: ~#{time_left / 60} minutes"
    end
  end

  # Test API connectivity (read-only)
  puts "\n" + ('-' * 80)
  puts 'Testing API Connectivity (read-only, no DB changes)'
  puts '-' * 80
  puts "\n"

  begin
    # Test 1: Order Count
    print '  Testing orderCount... '
    counts = client.order_count
    puts '✅'
    puts '    Order counts:'
    counts.each do |status, count|
      puts "      #{status}: #{count}"
    end

    # Test 2: Order List (last 24 hours)
    print "\n  Testing orderList (last 24h)... "
    ids = client.order_list(period: 1.day)
    puts '✅'
    puts "    Found #{ids.count} orders"

    if ids.any?
      puts '    Sample order IDs:'
      ids.first(3).each { |id| puts "      - #{id}" }

      # Test 3: Order Info for first order
      print "\n  Testing orderInfo (#{ids.first})... "
      details = client.order_info(ids.first)
      puts '✅'
      puts "    Order ID: #{details['OrderId']}"
      puts "    Status: #{details['OrderStatus']}"
      puts "    Order Time: #{details['OrderTime']}"
    end

    puts "\n✅ API Connection Working!"
  rescue YahooAPI::ReauthenticationRequiredError
    puts "\n❌ Reauthorization Required"
    puts "   Visit: #{client.authorization_url}"
  rescue YahooAPI::TokenExpiredError
    puts "\n❌ Token Expired"
    puts '   Attempting refresh...'

    begin
      client.ensure_authorized!
      puts '   ✅ Token refreshed successfully!'
    rescue StandardError => e
      puts "   ❌ Refresh failed: #{e.message}"
      puts "   Visit: #{client.authorization_url}"
    end
  rescue YahooAPI::APIError => e
    puts "\n❌ API Error"
    puts "   Code: #{e.api_code}"
    puts "   Message: #{e.api_message}"
  rescue StandardError => e
    puts "\n❌ Error: #{e.class}"
    puts "   Message: #{e.message}"
  end

else
  # Not authorized - show how to authenticate
  puts "\n⚠️  Not authorized. Please authenticate:"
  puts "\n1. Visit this URL in your browser:"
  puts "   #{client.authorization_url}"
  puts "\n2. After authorizing, you'll be redirected to:"
  puts "   #{config.redirect_uri}?code=XXXXX"
  puts "\n3. Exchange the code for tokens in the Rails console:"
  puts '   client = YahooAPI::Client.new'
  puts "   client.request_token('YOUR_CODE_HERE')"

  # Check for refresh token
  if client.auth.refresh_token_available?
    puts "\n💡 Refresh token available - attempting automatic refresh..."

    begin
      client.ensure_authorized!
      puts '   ✅ Successfully refreshed! Run this script again to test API.'
    rescue StandardError => e
      puts "   ❌ Refresh failed: #{e.message}"
      puts '   Manual re-authentication required (see above)'
    end
  end
end

puts "\n" + ('=' * 80)
puts "\n"
