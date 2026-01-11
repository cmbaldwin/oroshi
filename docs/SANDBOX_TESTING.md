# Sandbox End-to-End Testing

This document describes the automated end-to-end testing system for the Oroshi sandbox application.

## Overview

The sandbox E2E test (`test/sandbox_e2e_test.rb`) simulates a real user testing the complete sandbox lifecycle:

1. **Create** - Generates a fresh sandbox application
2. **Start** - Launches a Rails server
3. **Test** - Runs browser-based user journey tests
4. **Destroy** - Cleans up the sandbox

## Running the E2E Test

### Quick Start

```bash
# Run the complete E2E test
rake sandbox:test

# Or using rails test directly
bin/rails test test/sandbox_e2e_test.rb
```

**Estimated time:** 2-3 minutes

### What the Test Does

The E2E test performs the following user journey:

1. ✅ Creates sandbox with `bin/sandbox create`
2. ✅ Starts Rails server on port 3001
3. ✅ Opens browser (headless Chrome)
4. ✅ **Journey 1:** Sign in as admin user
5. ✅ **Journey 2:** Navigate through dashboard tabs
6. ✅ **Journey 3:** View suppliers page
7. ✅ **Journey 4:** View buyers page
8. ✅ **Journey 5:** View products page
9. ✅ **Journey 6:** View orders page
10. ✅ **Journey 7:** Sign out
11. ✅ Stops server
12. ✅ Destroys sandbox with `bin/sandbox destroy`

## Test Output

The test provides detailed console output:

```
================================================================================
Starting Sandbox E2E Test
================================================================================

📦 Creating sandbox...
✅ Sandbox created successfully

🚀 Starting sandbox server on port 3001...
✅ Server is ready (5s)
✅ Server started (PID: 12345)

================================================================================
Running User Journey Tests
================================================================================

👤 Journey 1: Sign in as admin...
✅ Signed in successfully

🏠 Journey 2: Navigate dashboard...
  - Clicking: ホーム
  - Clicking: 注文
  - Clicking: 仕入
  - Clicking: 出荷
✅ Dashboard navigation successful

🏭 Journey 3: View suppliers...
✅ Suppliers page loaded

🏢 Journey 4: View buyers...
✅ Buyers page loaded

📦 Journey 5: View products...
✅ Products page loaded

📋 Journey 6: View orders...
✅ Orders page loaded

👋 Journey 7: Sign out...
✅ Signed out successfully

✅ All user journey tests passed!

🛑 Stopping server...
✅ Server stopped

🧹 Destroying sandbox...
✅ Sandbox destroyed
```

## Rake Tasks

### sandbox:test

Runs the complete E2E test.

```bash
rake sandbox:test
```

### sandbox:create

Creates the sandbox application without running tests.

```bash
rake sandbox:create
```

### sandbox:destroy

Removes the sandbox application.

```bash
rake sandbox:destroy
```

### sandbox:reset

Destroys and recreates the sandbox.

```bash
rake sandbox:reset
```

### sandbox:server

Starts the sandbox server for manual testing.

```bash
rake sandbox:server
# Visit: http://localhost:3000
```

## Manual Testing Workflow

If you want to test the sandbox manually:

```bash
# 1. Create sandbox
rake sandbox:create

# 2. Start server
rake sandbox:server

# 3. In your browser, visit:
#    http://localhost:3000

# 4. Sign in with demo account:
#    Email: admin@oroshi.local
#    Password: password123

# 5. When done, destroy sandbox:
rake sandbox:destroy
```

## Requirements

The E2E test requires:

- ✅ Chrome or Chromium browser
- ✅ ChromeDriver (automatically managed by selenium-webdriver gem)
- ✅ PostgreSQL running locally
- ✅ Port 3001 available (test server)

## Test Configuration

### Server Port

The test uses port 3001 to avoid conflicts with any running development server (port 3000).

```ruby
SANDBOX_PORT = 3001
```

### Browser Configuration

The test runs in headless Chrome:

```ruby
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--window-size=1400,1400")
```

### Timeouts

```ruby
Capybara.default_max_wait_time = 10  # seconds
```

### Server Startup

The test waits up to 30 seconds for the server to start, checking the `/up` health check endpoint.

## Continuous Integration

To run this test in CI:

```yaml
# .github/workflows/sandbox_e2e.yml
name: Sandbox E2E Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 4.0.0
          bundler-cache: true

      - name: Install Chrome
        run: |
          wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
          sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
          sudo apt-get update
          sudo apt-get install -y google-chrome-stable

      - name: Run sandbox E2E test
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          DB_HOST: localhost
        run: rake sandbox:test
```

## Troubleshooting

### Server fails to start

**Error:** `Server failed to start after 30 seconds`

**Solutions:**
- Check PostgreSQL is running: `pg_isready`
- Check port 3001 is available: `lsof -i :3001`
- Increase timeout in `wait_for_server`

### Chrome/ChromeDriver issues

**Error:** `Selenium::WebDriver::Error::WebDriverError`

**Solutions:**
- Ensure Chrome is installed: `google-chrome --version`
- Update selenium-webdriver gem: `bundle update selenium-webdriver`
- Try running without headless: Remove `--headless` argument

### Database connection issues

**Error:** `ActiveRecord::ConnectionNotEstablished`

**Solutions:**
- Verify PostgreSQL is running
- Check database credentials in generated sandbox
- Ensure all 4 databases were created

### Sandbox creation fails

**Error:** `Failed to create sandbox`

**Solutions:**
- Run manually: `bin/sandbox create`
- Check Rails is installed: `rails -v`
- Check disk space is available

### Test hangs at sign in

**Error:** Test times out during sign in

**Solutions:**
- Verify demo users were seeded: Check `sandbox/db/seeds.rb` ran
- Check Devise is configured correctly
- Increase Capybara timeout

## Extending the Tests

To add more user journeys:

```ruby
def run_user_journey
  sign_in_as_admin
  navigate_dashboard
  view_suppliers
  # ... existing journeys

  # Add your new journey
  create_new_order
  view_invoice
  # etc.
end

private

def create_new_order
  puts "\n📝 Journey: Create new order..."

  visit oroshi_orders_path
  click_link "新規注文"

  # Fill in form
  select "得意先名", from: "order_buyer_id"
  fill_in "order_date", with: Date.today.to_s

  click_button "保存"

  assert_selector ".alert-success", text: /作成されました/
  puts "✅ Order created successfully"
end
```

## Best Practices

### Keep Tests Fast
- Test critical paths only
- Avoid testing every single feature
- Focus on smoke tests (does it load without errors?)

### Make Tests Stable
- Use explicit waits, not sleeps
- Use `assert_selector` with `wait: N`
- Check for absence of errors, not just presence of elements

### Make Tests Readable
- Use descriptive journey names
- Add console output for debugging
- Group related actions together

### Keep Tests Independent
- Each journey should work standalone
- Don't rely on previous journey state
- Clean up after yourself

## Performance

Typical execution times:

- Sandbox creation: ~45-60 seconds
- Server startup: ~5-10 seconds
- User journey tests: ~20-30 seconds
- Sandbox destruction: ~2-3 seconds

**Total:** ~2-3 minutes

## Future Improvements

Potential enhancements:

- [ ] Test with different user roles (VIP, regular user)
- [ ] Test onboarding flow for new users
- [ ] Test order creation end-to-end
- [ ] Test PDF generation
- [ ] Test real-time updates (Turbo Streams)
- [ ] Test mobile viewport
- [ ] Parallel test execution
- [ ] Screenshot capture on failure
- [ ] Video recording of test runs

## References

- [Capybara Documentation](https://rubydoc.info/github/teamcapybara/capybara)
- [Selenium WebDriver Documentation](https://www.selenium.dev/documentation/)
- [Rails System Testing Guide](https://guides.rubyonrails.org/testing.html#system-testing)
- [Minitest Documentation](https://docs.seattlerb.org/minitest/)

---

**Last Updated:** January 11, 2026
**Test Location:** `test/sandbox_e2e_test.rb`
**Rake Task:** `rake sandbox:test`
