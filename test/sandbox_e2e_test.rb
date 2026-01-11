# frozen_string_literal: true

require "test_helper"
require "capybara/minitest"
require "selenium-webdriver"
require "open3"

# End-to-End Sandbox Test
#
# This test creates a real sandbox application, starts a server,
# navigates through the application as a user would, then cleans up.
#
# Run with: bin/rails test test/sandbox_e2e_test.rb
#
# This is a slow test (~2-3 minutes) and should be run separately
# from the main test suite.
class SandboxE2ETest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  SANDBOX_DIR = File.expand_path("../sandbox", __dir__)
  SANDBOX_PORT = 3001 # Use different port to avoid conflicts

  def setup
    # Configure Capybara for this test
    Capybara.default_driver = :selenium_chrome_headless
    Capybara.app_host = "http://localhost:#{SANDBOX_PORT}"
    Capybara.default_max_wait_time = 10
    Capybara.server = :puma

    # Configure Selenium
    Capybara.register_driver :selenium_chrome_headless do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-gpu")
      options.add_argument("--window-size=1400,1400")

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end

    puts "\n" + "=" * 80
    puts "Starting Sandbox E2E Test"
    puts "=" * 80
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  test "complete sandbox lifecycle: create, test, destroy" do
    # Step 1: Ensure clean slate
    destroy_sandbox

    # Step 2: Create sandbox
    create_sandbox

    # Step 3: Start server and test
    with_sandbox_server do
      run_user_journey
    end

    # Step 4: Cleanup
    destroy_sandbox
  end

  private

  def create_sandbox
    puts "\n📦 Creating sandbox..."
    assert File.exist?("bin/sandbox"), "bin/sandbox script not found"

    result = run_command("bin/sandbox create")
    assert result[:success], "Failed to create sandbox: #{result[:stderr]}"
    assert Dir.exist?(SANDBOX_DIR), "Sandbox directory was not created"

    puts "✅ Sandbox created successfully"
  end

  def destroy_sandbox
    puts "\n🧹 Destroying sandbox..."

    if Dir.exist?(SANDBOX_DIR)
      result = run_command("bin/sandbox destroy")
      assert result[:success], "Failed to destroy sandbox: #{result[:stderr]}"
      refute Dir.exist?(SANDBOX_DIR), "Sandbox directory still exists after destroy"
      puts "✅ Sandbox destroyed"
    else
      puts "ℹ️  No sandbox to destroy"
    end
  end

  def with_sandbox_server
    puts "\n🚀 Starting sandbox server on port #{SANDBOX_PORT}..."

    # Start server in background
    server_pid = spawn(
      { "PORT" => SANDBOX_PORT.to_s },
      "cd #{SANDBOX_DIR} && bin/rails server -p #{SANDBOX_PORT}",
      out: "/dev/null",
      err: "/dev/null"
    )

    # Wait for server to be ready
    wait_for_server

    puts "✅ Server started (PID: #{server_pid})"

    begin
      yield
    ensure
      puts "\n🛑 Stopping server..."
      Process.kill("TERM", server_pid)
      Process.wait(server_pid)
      puts "✅ Server stopped"
    end
  end

  def wait_for_server(max_attempts: 30)
    require "net/http"
    require "uri"

    attempts = 0
    loop do
      begin
        uri = URI("http://localhost:#{SANDBOX_PORT}/up")
        response = Net::HTTP.get_response(uri)
        break if response.is_a?(Net::HTTPSuccess)
      rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL
        # Server not ready yet
      end

      attempts += 1
      raise "Server failed to start after #{max_attempts} seconds" if attempts > max_attempts

      sleep 1
    end

    puts "✅ Server is ready (#{attempts}s)"
  end

  def run_user_journey
    puts "\n" + "=" * 80
    puts "Running User Journey Tests"
    puts "=" * 80

    # Journey 1: Sign in as admin
    sign_in_as_admin

    # Journey 2: Navigate dashboard
    navigate_dashboard

    # Journey 3: View suppliers
    view_suppliers

    # Journey 4: View buyers
    view_buyers

    # Journey 5: View products
    view_products

    # Journey 6: View orders
    view_orders

    # Journey 7: Sign out
    sign_out

    puts "\n✅ All user journey tests passed!"
  end

  def sign_in_as_admin
    puts "\n👤 Journey 1: Sign in as admin..."

    visit "/"

    # Should redirect to sign in
    assert_current_path "/users/sign_in", ignore_query: true
    assert_selector "h2", text: /ログイン|Sign in/i

    # Fill in credentials
    fill_in "login", with: "admin@oroshi.local"
    fill_in "user_password", with: "password123"

    # Submit form
    click_button "ログイン"

    # Should be on dashboard
    assert_current_path "/", ignore_query: true
    assert_selector "#navbar_t", wait: 5

    puts "✅ Signed in successfully"
  end

  def navigate_dashboard
    puts "\n🏠 Journey 2: Navigate dashboard..."

    visit "/"

    # Check for key dashboard elements
    assert_selector "#dashboard-nav", wait: 5
    assert_text /ダッシュボード|Dashboard/i

    # Click through dashboard tabs
    within "#dashboard-nav" do
      # Find all navigation links
      links = all("a.nav-link")

      links.each_with_index do |link, index|
        text = link.text.strip
        puts "  - Clicking: #{text}"

        link.click
        sleep 0.5 # Wait for Turbo

        # Ensure no errors
        assert_no_selector ".alert-danger", wait: 1
      end
    end

    puts "✅ Dashboard navigation successful"
  end

  def view_suppliers
    puts "\n🏭 Journey 3: View suppliers..."

    # Navigate to suppliers
    within "#navbar_t" do
      click_link "仕入先", match: :first
    end

    # Should see suppliers list
    assert_selector "h1", text: /仕入先/
    assert_no_text "500"
    assert_no_text "404"

    puts "✅ Suppliers page loaded"
  end

  def view_buyers
    puts "\n🏢 Journey 4: View buyers..."

    # Navigate to buyers
    within "#navbar_t" do
      click_link "得意先", match: :first
    end

    # Should see buyers list
    assert_selector "h1", text: /得意先/
    assert_no_text "500"
    assert_no_text "404"

    puts "✅ Buyers page loaded"
  end

  def view_products
    puts "\n📦 Journey 5: View products..."

    # Navigate to products
    within "#navbar_t" do
      click_link "商品", match: :first
    end

    # Should see products list
    assert_selector "h1", text: /商品/
    assert_no_text "500"
    assert_no_text "404"

    puts "✅ Products page loaded"
  end

  def view_orders
    puts "\n📋 Journey 6: View orders..."

    # Navigate to orders
    within "#navbar_t" do
      click_link "注文", match: :first
    end

    # Should see orders list or form
    assert_no_text "500"
    assert_no_text "404"

    puts "✅ Orders page loaded"
  end

  def sign_out
    puts "\n👋 Journey 7: Sign out..."

    # Click user dropdown
    within "#navbar_t" do
      # Look for dropdown toggle (usually has user email or icon)
      dropdown = find("a[data-bs-toggle='dropdown']", match: :first)
      dropdown.click
    end

    # Click sign out link
    click_link "ログアウト"

    # Should be back on sign in page
    assert_current_path "/users/sign_in", ignore_query: true
    assert_selector "h2", text: /ログイン|Sign in/i

    puts "✅ Signed out successfully"
  end

  def run_command(command)
    stdout, stderr, status = Open3.capture3(command)
    {
      success: status.success?,
      stdout: stdout,
      stderr: stderr,
      status: status
    }
  end
end
