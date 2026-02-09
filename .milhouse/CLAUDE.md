# Milhouse Instructions - Oroshi Test Suite Fixes

## Project Overview

**Goal**: Fix the Oroshi Rails Engine test suite to achieve 100% pass rate (currently 647 tests with 9 failures).

**Context**: Oroshi is a Rails 8.1.1 engine gem for wholesale order management. The test suite uses Test::Unit (NOT RSpec) with FactoryBot and Capybara. This project focuses on fixing test failures, missing factories, and configuration issues.

**Repository**: https://github.com/cmbaldwin/oroshi  
**Branch**: Working in main branch of oroshi engine

## Current Status

- **Total Tests**: 647 examples
- **Failures**: 9 tests failing
- **Errors**: Factory and WebMock configuration issues
- **Priority**: Fix in order US-001 → US-002 → US-003 → US-004 → US-005

## Tech Stack

- **Rails**: 8.1.1 (Ruby 4.0.0)
- **Testing**: Test::Unit + FactoryBot + Capybara
- **Database**: PostgreSQL (4 separate databases)
- **Background Jobs**: Solid Queue
- **Assets**: Propshaft + importmap

## Critical Testing Patterns

### Running Tests

```bash
# Run all tests
cd /Users/cody/Dev/oroshi && bin/rails test

# Run specific test file
bin/rails test test/jobs/oroshi/mailer_job_test.rb

# Run tests for a directory
bin/rails test test/jobs/

# Run with verbose output
bin/rails test --verbose

# Run sandbox E2E test
bin/rails test test/sandbox_e2e_test.rb
```

### Factory Locations

```bash
# All factories are in test/factories/oroshi/
test/factories/oroshi/
  addresses.rb
  buyer_categories.rb
  buyers.rb
  invoices.rb
  materials.rb
  orders.rb
  products.rb
  suppliers.rb
  # ... etc
```

### Factory Usage Patterns

```ruby
# Correct - use namespaced factory names
create(:oroshi_order)
create(:oroshi_buyer)
create(:oroshi_product)

# Check if factory exists before creating
FactoryBot.factories.registered?(:oroshi_message)
```

### WebMock Configuration

```ruby
# In test_helper.rb or specific test files
require 'webmock/minitest'

# Allow localhost connections for sandbox tests
WebMock.allow_net_connect!(allow_localhost: true)

# Or disable for specific tests
WebMock.disable!
# ... test code ...
WebMock.enable!
```

## Documentation Search

Search project documentation before making changes:

```bash
# Search in main Oroshi docs
qmd search "factory patterns" -c oroshi

# Search for test conventions
qmd search "test::unit patterns" -c oroshi

# Search for WebMock usage
qmd search "webmock configuration" -c oroshi
```

## Quality Checks

Run these before marking a story complete:

```bash
# 1. Run tests for the area you fixed
bin/rails test test/jobs/  # or relevant path

# 2. Check rubocop (optional for test fixes)
bundle exec rubocop test/jobs/oroshi/mailer_job_test.rb

# 3. Verify specific user story acceptance criteria
# For US-001: bin/rails test test/jobs/
# For US-002: bin/rails test test/sandbox_e2e_test.rb
# For US-003: bin/rails test --verbose
# For US-005: bin/rails test (all tests)
```

## Project Conventions

### Testing Conventions

1. **Test::Unit, NOT RSpec** - Use `assert_equal`, `assert_not_nil`, not `expect().to`
2. **Factories in test/factories/** - All models have FactoryBot factories
3. **Namespaced Models** - All Oroshi models: `Oroshi::Order`, `Oroshi::Buyer`, etc.
4. **Tables Prefixed** - All tables: `oroshi_orders`, `oroshi_buyers`, etc.
5. **User Model Exception** - `User` model is NOT namespaced (application-level)

### File Naming Patterns

```
# Test files mirror app structure
app/jobs/oroshi/mailer_job.rb
→ test/jobs/oroshi/mailer_job_test.rb

app/models/oroshi/order.rb
→ test/models/oroshi/order_test.rb

# Factories
app/models/oroshi/order.rb
→ test/factories/oroshi/orders.rb
```

### Factory Naming

```ruby
# Factory definition
FactoryBot.define do
  factory :oroshi_order, class: "Oroshi::Order" do
    # attributes
  end
end

# Usage in tests
create(:oroshi_order)
build(:oroshi_order)
```

## Current Focus (from prd.json)

Frontend bug fixes and UI polish:
1. **CSS 404** - Fix SCSS @import for ultimate_turbo_modal_bootstrap (remove .css extension)
2. **ScrollSpy error** - Add missing Bootstrap import in revenue_controller.js
3. **Order inline editing** - Fix Stimulus action bindings and controller namespace mismatches
4. **Modal standardization** - Refactor order modal to match supply modal pattern (native dialog API)
5. **Legacy text** - Replace 牡蠣 references with generic supply terms
6. **Supply dates undefined** - Add null guards in supply_date_input_controller.js
7. **Filter UX** - Add reset button and responsive improvements

## Progress Tracking

Update `progress.txt` after each story with:

- What was fixed
- Changes made (files edited)
- Test results (before/after pass count)
- Any learnings or gotchas

## Commit Message Format

```
fix: [brief description]

[Detailed explanation of what was fixed and why]

Fixes US-XXX
```

Example:

```
fix: create missing message factory for mailer job tests

Added oroshi_message factory in test/factories/oroshi/messages.rb
with required attributes (subject, body, recipient_id). Updated
mailer job test to use correct factory.

Fixes US-001
```

## Commands Reference

```bash
# Navigate to project
cd /Users/cody/Dev/oroshi

# Install dependencies
bundle install

# Run migrations
bin/rails db:migrate RAILS_ENV=test

# Load test schema
bin/rails db:test:prepare

# Run all tests
bin/rails test

# Check factory list
bin/rails runner "puts FactoryBot.factories.map(&:name).sort"

# Start sandbox (if needed)
bin/sandbox

# Destroy sandbox
bin/sandbox destroy
```

## Important Files

- **Test Helper**: `test/test_helper.rb` - WebMock and test configuration
- **Factories**: `test/factories/oroshi/*.rb` - All FactoryBot factories
- **Main Tests**: `test/{models,controllers,jobs,integration,system}/oroshi/*.rb`
- **E2E Test**: `test/sandbox_e2e_test.rb` - Sandbox lifecycle test
- **PRD**: `.milhouse/prd.json` - User stories to complete
- **Progress**: `.milhouse/progress.txt` - Work log

## Workflow

1. Read user story from prd.json
2. Search documentation: `qmd search "relevant topic"`
3. Identify affected files
4. Make minimal changes to fix issue
5. Run tests: `bin/rails test [path]`
6. Verify acceptance criteria met
7. Update progress.txt with changes
8. Commit with "Fixes US-XXX" message
9. Update prd.json: set `"passes": true`
10. Move to next story

## Getting Unstuck

If you're stuck:

1. Check main CLAUDE.md: `/Users/cody/Dev/oroshi/CLAUDE.md`
2. Search docs: `qmd search "your question"`
3. Check existing tests for patterns: `grep -r "similar pattern" test/`
4. Look at factory definitions: `cat test/factories/oroshi/*.rb`
5. Check model validations: `cat app/models/oroshi/[model].rb`

---

**Last Updated**: February 5, 2026  
**Current Story**: US-001 (Fix missing 'message' factory)  
**Test Pass Rate**: 638/647 (98.6%)
