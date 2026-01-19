# agent-browser Skill: Ruby on Rails Integration Guide

**Skill Name:** agent-browser (Browser Automation CLI)

## Overview

Integrate `agent-browser` into your Ruby on Rails project for headless browser automation without requiring npm in your propshaft/importmaps setup. This guide supports both local development and CI/CD environments.

## What is agent-browser?

A fast, headless browser automation CLI for AI agents that enables web testing, form filling, screenshots, and data extraction. It's built with Rust for performance with a Node.js fallback, making it perfect for Rails projects using propshaft (Rails 8+ asset pipeline).

## Local Development Setup

### Prerequisites

- Ruby on Rails 7+ (works with propshaft/importmaps)
- Node.js 18+ (for running agent-browser, not required in your Rails app)
- Homebrew (macOS) or package manager (Linux)

### Installation (Development Environment Only)

#### Option 1: Global Installation (Recommended for Development)

```bash
# Install globally as a development tool
npm install -g agent-browser
agent-browser install  # Download Chromium (~240MB)
```

#### Option 2: Project-Local Installation (Without npm in your Rails app)

Create a separate `tooling/` directory for development dependencies:

```bash
# Create local tooling directory
mkdir -p tooling
cd tooling
npm init -y
npm install --save-dev agent-browser

# Back in root, add to .gitignore
echo "tooling/node_modules" >> .gitignore
```

Then use it via:

```bash
./tooling/node_modules/.bin/agent-browser [command]
```

#### Option 3: Direct Binary Installation (No npm needed at runtime)

For macOS or Linux, download the pre-built binary:

```bash
# macOS ARM64 (Apple Silicon)
wget https://github.com/vercel-labs/agent-browser/releases/download/v0.5.0/agent-browser-darwin-arm64
chmod +x agent-browser-darwin-arm64
mv agent-browser-darwin-arm64 /usr/local/bin/agent-browser

# macOS x64
wget https://github.com/vercel-labs/agent-browser/releases/download/v0.5.0/agent-browser-darwin-x64
chmod +x agent-browser-darwin-x64
mv agent-browser-darwin-x64 /usr/local/bin/agent-browser

# Linux x64
wget https://github.com/vercel-labs/agent-browser/releases/download/v0.5.0/agent-browser-linux-x64
chmod +x agent-browser-linux-x64
mv agent-browser-linux-x64 /usr/local/bin/agent-browser
```

First time setup:

```bash
agent-browser install
```

### Development Workflow

#### Quick Start

```bash
# Navigate to a page
agent-browser open https://example.com

# Get interactive elements with refs
agent-browser snapshot -i

# Click an element
agent-browser click @e1

# Fill a form field
agent-browser fill @e2 "input text"

# Take a screenshot
agent-browser screenshot screenshot.png

# Close browser
agent-browser close
```

#### Common Development Tasks

**Form Testing:**

```bash
agent-browser open http://localhost:3000/login
agent-browser snapshot -i
# Output shows refs like: textbox "Email" [ref=e1], textbox "Password" [ref=e2], button "Sign In" [ref=e3]
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser screenshot form-submission.png
```

**Element Inspection:**

```bash
agent-browser open http://localhost:3000
agent-browser snapshot -i -d 3  # Interactive elements only, max depth 3
agent-browser get text @e1      # Get specific element text
agent-browser get url           # Get current page URL
```

**Waiting for Elements:**

```bash
# Wait for element to appear
agent-browser wait @e1

# Wait for specific text
agent-browser wait --text "Welcome"

# Wait for network idle
agent-browser wait --load networkidle
```

## CI/CD Integration

### GitHub Actions Setup

Create `.github/workflows/browser-tests.yml`:

```yaml
name: Browser Automation Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "18"

      - name: Install agent-browser
        run: |
          npm install -g agent-browser
          agent-browser install --with-deps  # Install system deps on Linux

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true

      - name: Setup Rails
        run: |
          bundle install
          rails assets:precompile

      - name: Start Rails server
        run: |
          bundle exec rails s -d -p 3000
          sleep 5  # Wait for server to start

      - name: Run browser automation tests
        run: |
          agent-browser open http://localhost:3000
          agent-browser snapshot -i --json > snapshot.json
          # Add your test assertions here

      - name: Upload artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: browser-screenshots
          path: "*.png"
```

### GitLab CI Setup

Create `.gitlab-ci.yml`:

```yaml
stages:
  - test

browser_tests:
  stage: test
  image: node:18
  before_script:
    - apt-get update && apt-get install -y ruby ruby-dev build-essential
    - npm install -g agent-browser
    - agent-browser install --with-deps
    - ruby -v && gem install bundler
  script:
    - bundle install
    - bundle exec rails s -d -p 3000
    - sleep 5
    - agent-browser open http://localhost:3000
    - agent-browser snapshot -i --json > snapshot.json
  artifacts:
    paths:
      - "*.png"
    when: always
```

### Vercel Deployment with agent-browser

For serverless deployments, use the lightweight Chromium build:

```bash
# In your Vercel project, use environment variables
AGENT_BROWSER_EXECUTABLE_PATH=/opt/chromium/chromium
```

Or in your deployment script:

```bash
npm install -g agent-browser @sparticuz/chromium
agent-browser --executable-path $(node -e "console.log(require('@sparticuz/chromium').executablePath)") open https://example.com
```

## Key Commands Reference

### Navigation

```bash
agent-browser open <url>           # Navigate to URL
agent-browser back                 # Go back
agent-browser forward              # Go forward
agent-browser reload               # Reload page
agent-browser close                # Close browser
```

### Snapshot & Analysis

```bash
agent-browser snapshot             # Full accessibility tree
agent-browser snapshot -i          # Interactive elements only (recommended)
agent-browser snapshot -c          # Compact output
agent-browser snapshot -d 3        # Limit depth to 3
agent-browser snapshot --json      # Machine-readable JSON output
```

### Interactions (using refs from snapshot)

```bash
agent-browser click @e1            # Click element
agent-browser fill @e2 "text"      # Clear and type
agent-browser type @e2 "text"      # Type without clearing
agent-browser press Enter          # Press key
agent-browser hover @e1            # Hover element
agent-browser check @e1            # Check checkbox
agent-browser select @e1 "option"  # Select dropdown
agent-browser scroll down 500      # Scroll page
```

### Information Retrieval

```bash
agent-browser get text @e1         # Get element text
agent-browser get value @e1        # Get input value
agent-browser get title            # Get page title
agent-browser get url              # Get current URL
agent-browser get count <sel>      # Count elements
```

### Screenshots & State

```bash
agent-browser screenshot                 # Screenshot to stdout
agent-browser screenshot path.png        # Save to file
agent-browser screenshot --full          # Full page screenshot
agent-browser state save auth.json       # Save auth state
agent-browser state load auth.json       # Load saved state
```

### Waiting

```bash
agent-browser wait @e1                   # Wait for element visible
agent-browser wait 2000                  # Wait milliseconds
agent-browser wait --text "Success"      # Wait for text
agent-browser wait --url "**/dashboard"  # Wait for URL pattern
agent-browser wait --load networkidle    # Wait for network idle
```

## Common Patterns

### Testing Form Submission

```bash
agent-browser open http://localhost:3000/contact
agent-browser snapshot -i
agent-browser fill @e1 "John Doe"           # Name field
agent-browser fill @e2 "john@example.com"   # Email field
agent-browser fill @e3 "Test message"       # Message field
agent-browser click @e4                     # Submit button
agent-browser wait --url "**/thank-you"
agent-browser screenshot success.png
```

### Testing With Authentication

```bash
# First time: save authenticated state
agent-browser open http://localhost:3000/login
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser state save auth.json

# Later sessions: load saved state
agent-browser state load auth.json
agent-browser open http://localhost:3000/dashboard
agent-browser snapshot -i
```

### Testing Multiple Pages in Sequence

```bash
agent-browser open http://localhost:3000/products
agent-browser snapshot -i > products.json
agent-browser click @e5  # View details
agent-browser screenshot product-detail.png
agent-browser click @e10 # Add to cart
agent-browser click @e15 # View cart
agent-browser screenshot cart.png
```

## Debugging Tips

### Show Browser Window (Headed Mode)

```bash
agent-browser open example.com --headed
```

### View Page Errors

```bash
agent-browser errors
agent-browser console
```

### Debug JSON Output

```bash
agent-browser snapshot -i --json | jq .
agent-browser get text @e1 --json
```

### Session Management

```bash
agent-browser --session test1 open site-a.com
agent-browser --session test2 open site-b.com
agent-browser session list
```

## Rails-Specific Integration

### Add to Gemfile (for Rails test infrastructure)

```ruby
group :test do
  gem 'capybara'
  # Note: You don't need capybara-playwright; use agent-browser directly
end
```

### Create a Test Helper

Create `test/helpers/browser_automation_helper.rb`:

```ruby
module BrowserAutomationHelper
  def run_agent_browser(*args)
    command = ['agent-browser', *args].join(' ')
    `#{command}`
  end

  def browser_snapshot(interactive_only: true)
    flags = interactive_only ? '-i' : ''
    JSON.parse(run_agent_browser("snapshot #{flags} --json"))
  end

  def browser_click(ref)
    run_agent_browser("click @#{ref}")
  end

  def browser_fill(ref, text)
    run_agent_browser("fill @#{ref} #{text.inspect}")
  end
end
```

### Usage in Tests

```ruby
class BrowserAutomationTest < ActiveSupport::TestCase
  include BrowserAutomationHelper

  test "login flow" do
    run_agent_browser "open http://localhost:3000/login"
    snapshot = browser_snapshot

    # Find element refs from snapshot
    browser_fill("e1", "user@example.com")
    browser_fill("e2", "password123")
    browser_click("e3")

    run_agent_browser "wait --url '**/dashboard'"
    assert_equal "http://localhost:3000/dashboard",
                 run_agent_browser("get url").strip
  end
end
```

## No npm Required in Production

**Important:** Your Rails application itself does NOT need npm. agent-browser runs as a standalone CLI tool:

- ✓ Works with propshaft (Rails 8+ asset pipeline)
- ✓ Works with importmaps (no build step)
- ✓ No npm in your Gemfile
- ✓ No JavaScript bundling required
- ✓ Just shell out to the agent-browser binary

The only npm requirement is during development (or in CI/CD containers).

## Troubleshooting

### Binary not found

```bash
which agent-browser  # Check if installed globally
echo $PATH           # Verify /usr/local/bin is in PATH
```

### Chromium installation fails

```bash
# Linux: Install system dependencies
agent-browser install --with-deps

# Or manually:
npx playwright install-deps chromium
```

### Port already in use in CI

```bash
# Use a different port for Rails
bundle exec rails s -p 3001

# Then update agent-browser URLs
agent-browser open http://localhost:3001
```

### Permission denied errors

```bash
# Ensure Chromium can write to temp directory
export TMPDIR=/tmp
agent-browser open example.com
```

## Resources

- **Official Docs:** https://agent-browser.dev
- **GitHub:** https://github.com/vercel-labs/agent-browser
- **SKILL.md:** https://github.com/vercel-labs/agent-browser/blob/main/skills/agent-browser/SKILL.md
- **npm Package:** https://www.npmjs.com/package/agent-browser

## Next Steps

1. **Local Development:** Install agent-browser globally or locally per the Installation section
2. **Test It:** Run `agent-browser open https://example.com && agent-browser snapshot -i`
3. **Rails Integration:** Add helper methods to your test suite
4. **CI/CD:** Configure GitHub Actions or GitLab CI using the provided templates
5. **Production:** For serverless, use the executable path configuration

---

_Last Updated: January 2026_
_Compatible with: Rails 7+, propshaft, importmaps_
