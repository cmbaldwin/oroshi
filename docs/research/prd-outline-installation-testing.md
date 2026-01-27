# PRD: Installation Testing & Route Refactoring

**Date:** January 25, 2026  
**Epic:** Gem Installation & Testing Infrastructure  
**Priority:** CRITICAL  
**Estimated Effort:** 2-3 weeks  
**Branch:** `refactor/installation-testing`

---

## Overview

This PRD covers two related initiatives:

1. **Route Refactoring** (CRITICAL) - Remove dual route files to fix asset loading and installation issues
2. **Installation Testing** (HIGH) - Add automated testing for gem installation in fresh Rails apps

These initiatives are related because the route refactoring fixes the root cause that prevents proper installation testing.

---

## User Stories

### US-R01: Remove Dual Route Files

**As a** Rails engine maintainer  
**I want** to use a single route file pattern  
**So that** asset loading works correctly and follows industry standards

**Priority:** 1  
**Story Points:** 3  
**Acceptance Criteria:**
- Delete `config/routes_standalone_app.rb`
- Move all routes to `config/routes.rb` in engine namespace
- Move Devise routes from standalone to engine routes
- No references to `routes_standalone_app.rb` in codebase
- Git commit with clear message explaining change
- All tests pass

**Notes:**
- CRITICAL - Blocks Ralph's US-016 through US-022
- Root cause of oroshi-moab installation failure
- Non-standard pattern not used by any mature Rails engine

---

### US-R02: Update Sandbox Generation Script

**As a** developer working on Oroshi  
**I want** the sandbox to generate its own routes file  
**So that** sandbox is a true separate Rails application

**Priority:** 2  
**Story Points:** 2  
**Acceptance Criteria:**
- Update `bin/sandbox` script
- Script generates `sandbox/config/routes.rb` with engine mount
- Routes file not copied from gem
- Sandbox generation still creates complete working app
- `bin/sandbox` script documented with comments
- Sandbox works when created

**Dependencies:** US-R01

---

### US-R03: Update Test Environment Configuration

**As a** developer running tests  
**I want** tests to use engine routes directly  
**So that** tests don't have route/asset loading conflicts

**Priority:** 3  
**Story Points:** 2  
**Acceptance Criteria:**
- Review `test/test_helper.rb` for standalone route loading
- Remove any loading of `routes_standalone_app.rb`
- System tests use engine routes via `oroshi.*` helpers
- All existing tests pass after changes
- No asset loading errors in test output

**Dependencies:** US-R01

---

### US-R04: Verify oroshi-moab Installation Works

**As a** user installing Oroshi in a Rails app  
**I want** installation to work correctly  
**So that** I can use Oroshi in my application

**Priority:** 4  
**Story Points:** 1  
**Acceptance Criteria:**
- Clone/update oroshi-moab project
- Run `bundle install` successfully
- Run `rails generate oroshi:install` successfully
- Run `rails db:migrate` successfully
- Start server and visit `/oroshi` - dashboard loads
- Assets load correctly (CSS and JavaScript)
- No console errors
- Document any additional setup steps discovered

**Dependencies:** US-R01, US-R02, US-R03

---

### US-R05: Update Documentation for Route Pattern

**As a** contributor or user  
**I want** documentation to explain the route configuration  
**So that** I understand the architecture and don't reintroduce dual routes

**Priority:** 5  
**Story Points:** 2  
**Acceptance Criteria:**
- README.md updated with architecture section explaining engine routes
- CLAUDE.md updated with route pattern explanation
- `.ralph/prompt.md` updated with route gotcha
- REALIZATIONS.md entry added about single route file pattern
- Comment in `config/routes.rb` explaining engine namespace

**Dependencies:** US-R01

---

### US-I01: Create Install Generator

**As a** user installing Oroshi  
**I want** a generator that sets up everything automatically  
**So that** I don't have to manually configure the gem

**Priority:** 6  
**Story Points:** 5  
**Acceptance Criteria:**
- Generator at `lib/generators/oroshi/install/install_generator.rb` created
- Generator copies migrations
- Generator creates initializer at `config/initializers/oroshi.rb`
- Generator adds `mount Oroshi::Engine` to `config/routes.rb`
- Generator runs `db:migrate`
- Generator loads Solid schemas (queue, cache, cable)
- Generator shows helpful next steps message
- Generator has comprehensive comments

**Dependencies:** US-R01, US-R02, US-R03, US-R04, US-R05

---

### US-I02: Create Generator Tests

**As a** maintainer  
**I want** automated tests for the install generator  
**So that** I know the generator works correctly

**Priority:** 7  
**Story Points:** 3  
**Acceptance Criteria:**
- Test file at `test/lib/generators/oroshi/install_generator_test.rb` created
- Test verifies initializer created
- Test verifies routes updated
- Test verifies migrations copied
- Tests use Rails::Generators::TestCase
- Tests follow Test::Unit patterns (not RSpec)
- All generator tests pass

**Dependencies:** US-I01

---

### US-I03: Add README Installation Instructions

**As a** user  
**I want** clear installation instructions  
**So that** I can install Oroshi correctly

**Priority:** 8  
**Story Points:** 2  
**Acceptance Criteria:**
- README.md has complete Installation section
- Step-by-step instructions provided
- Solid schema setup documented
- Multi-database configuration explained
- Troubleshooting section added
- Common errors documented with solutions
- Instructions tested in fresh Rails app

**Dependencies:** US-I01

---

### US-I04: Create CI Installation Test

**As a** maintainer  
**I want** automated CI tests for installation  
**So that** installation issues are caught before release

**Priority:** 9  
**Story Points:** 5  
**Acceptance Criteria:**
- GitHub Actions workflow created at `.github/workflows/installation.yml`
- Workflow tests Rails 7.1 and 8.0
- Workflow tests Ruby 3.2 and 3.3
- Workflow creates fresh Rails app
- Workflow installs Oroshi
- Workflow verifies installation succeeded
- Workflow runs on push to main/develop
- Workflow runs on pull requests

**Dependencies:** US-I01, US-I03

---

### US-I05: Create Installation Verification Command

**As a** user  
**I want** a command to verify installation  
**So that** I know everything is set up correctly

**Priority:** 10  
**Story Points:** 3  
**Acceptance Criteria:**
- Rake task `oroshi:verify_installation` created
- Task checks routes mounted correctly
- Task checks initializer exists
- Task checks databases configured
- Task checks migrations run
- Task provides helpful output
- Task exits with success/failure code

**Dependencies:** US-I01

---

### US-I06: Test oroshi-moab Installation End-to-End

**As a** QA tester  
**I want** documented proof that oroshi-moab installation works  
**So that** we know the refactoring succeeded

**Priority:** 11  
**Story Points:** 2  
**Acceptance Criteria:**
- Document created at `docs/testing/oroshi-moab-installation-test.md`
- Document has step-by-step test procedure
- All steps executed successfully
- Screenshots/evidence captured
- Any issues found documented
- Workarounds (if needed) documented
- Test repeatable by others

**Dependencies:** All other stories

---

## Epic Breakdown

### Epic 1: Route Configuration Refactoring (CRITICAL)

**Stories:** US-R01 through US-R05  
**Estimated Effort:** 3-5 days  
**Impact:** Unblocks Ralph's tests and oroshi-moab installation

**Goal:** Fix root cause of asset loading and installation failures

### Epic 2: Installation Testing Infrastructure (HIGH)

**Stories:** US-I01 through US-I06  
**Estimated Effort:** 1-2 weeks  
**Impact:** Makes installation reliable and automated

**Goal:** Provide complete installation automation and testing

---

## Dependencies

```
US-R01 (Remove dual routes)
  ├─→ US-R02 (Update sandbox)
  ├─→ US-R03 (Update tests)
  ├─→ US-R04 (Verify oroshi-moab)
  └─→ US-R05 (Update docs)
       └─→ US-I01 (Create generator)
            ├─→ US-I02 (Generator tests)
            ├─→ US-I03 (README)
            │    └─→ US-I04 (CI tests)
            └─→ US-I05 (Verification command)
                 └─→ US-I06 (E2E test)
```

---

## Success Criteria

### Epic 1 Complete When:
- ✅ No `routes_standalone_app.rb` file exists
- ✅ Sandbox generates its own routes
- ✅ All tests pass (including Ralph's blocked tests)
- ✅ oroshi-moab installation works
- ✅ Documentation updated

### Epic 2 Complete When:
- ✅ `rails generate oroshi:install` works completely
- ✅ Generator has tests that pass
- ✅ README has complete installation instructions
- ✅ CI tests installation on multiple Rails/Ruby versions
- ✅ Verification command helps users diagnose issues
- ✅ oroshi-moab installation tested and documented

---

## Release Plan

**Version:** 0.2.0  
**Type:** Bug fix (fixing non-standard pattern)  
**Breaking Changes:** None (was already broken for real installations)

---

## References

- Research findings: `docs/research/findings-gem-installation-testing.md`
- Gap analysis: `docs/research/oroshi-installation-gaps.md`
- Ralph's investigation: `.ralph/progress.txt` [2026-01-25 13:31:00]
