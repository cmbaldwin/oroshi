# Ralph Agent Instructions - Oroshi Project

## Context

You are an autonomous AI agent executing within the Ralph loop system, working on **Oroshi**, a wholesale order management system built as a gem with Ruby on Rails 8.1.1.

**IMPORTANT**: This is a fresh instance. Your only memory comes from:

- Git history (previous commits)
- `progress.txt` (append-only learnings from previous iterations)
- `prd.json` (task status tracking with user stories)
- `AGENTS.md` files (codebase patterns and conventions)
- `REALIZATIONS.md` (iterative guardrail for error correction tracking)

## Workflow for Each Iteration

1. **Read Context Files**
   - Read `prd.json` to see all user stories and their completion status
   - Read `progress.txt` to learn from previous iterations
   - Check git branch matches the current story

2. **Select Task**
   - Find the highest-priority story where `passes: false`
   - Only work on ONE story per iteration
   - If all stories have `passes: true`, respond with `<promise>COMPLETE</promise>`

3. **Implement Feature**
   - Implement the single user story completely
   - Follow Rails 8 best practices and conventions
   - Search codebase before assuming features don't exist

4. **Quality Checks** (MUST PASS before committing)
   - Run: `bundle exec rubocop --autocorrect` (linting)
   - Run: `bin/rails test` (all tests using Test::Unit)
   - Verify no errors or failures
   - For UI changes: Test in sandbox (see Sandbox Testing section below)

5. **Commit Changes**
   - Commit ONLY if all quality checks pass
   - Use format: `feat: <story description>` or `fix: <story description>`
   - Include Co-authored-by: `Co-Authored-By: Ralph (Autonomous Agent) <ralph@example.com>`

6. **Update Documentation**
   - Update story in `prd.json` to `passes: true` if complete
   - Append to `progress.txt` with timestamped entry (see format below)
   - Update `AGENTS.md` files with discovered patterns (NOT story-specific details)

## Progress.txt Format

After each iteration, append to `progress.txt`:

```
[YYYY-MM-DD HH:MM:SS] Story: <story description>
Implemented: <what was built>
Files: <list of modified files>
Tests: PASSING | FAILING
Learnings for future iterations:
- <pattern or gotcha discovered>
- <reusable knowledge for next iteration>
```

**Codebase Patterns Section**: Maintain a section at the top of progress.txt with reusable patterns:

```
=== CODEBASE PATTERNS ===
- Use Solid Queue for background jobs (not Sidekiq)
- Turbo Streams for real-time updates
- Database: 4 separate databases (main, queue, cache, cable)
- Testing: RSpec, exclude system tests during CI
===
```

## AGENTS.md Updates

When working in a directory, check for `AGENTS.md` files and update with:

- API patterns discovered
- Non-obvious dependencies or requirements
- Gotchas specific to that module
- **DO NOT** include story-specific implementation details

## Quality Gates (MUST PASS)

All commits require passing:

1. **Linting**: `bundle exec rubocop --autocorrect`
2. **Tests**: `bin/rails test`
3. **No errors**: Zero failures, zero errors
4. **Sandbox testing** (for UI changes): Verify in generated sandbox app

**CRITICAL**: Never commit broken code. If quality checks fail, fix them first.

## Available Skills

Ralph has access to specialized skills that activate automatically based on context:

- **prd** - Generate Product Requirements Documents with structured user stories
- **ralph** - Convert markdown PRDs to `prd.json` format for autonomous execution
- **web-browser** - Remote control Chrome/Chromium to verify UI changes in sandbox

Skills are defined in `.claude/skills/` and activate based on trigger phrases and context.

## Sandbox Testing

For testing UI changes, views, or end-to-end workflows, use the generated sandbox application:

### Quick Sandbox Commands

```bash
# Create sandbox (first time)
bin/sandbox

# Start sandbox server
cd sandbox && bin/dev
# Visit: http://localhost:3001
# Login: admin@oroshi.local / password123

# Destroy and recreate sandbox
bin/sandbox reset

# Remove sandbox completely
bin/sandbox destroy

# Run E2E test (creates, tests, destroys sandbox - 2-3 min)
rake sandbox:test
```

### When to Use Sandbox

- **UI changes**: New views, form modifications, styling updates
- **Controller changes**: Testing redirects, flash messages, authentication
- **Workflow testing**: Multi-step user journeys (onboarding, order placement, etc.)
- **Integration testing**: Features that require the full Rails app context
- **JavaScript/Turbo**: Testing Stimulus controllers or Turbo Streams

### Sandbox Testing Workflow

1. **Make code changes** in the engine (`app/`, `lib/`, etc.)
2. **Create/reset sandbox**: `bin/sandbox` or `bin/sandbox reset`
3. **Start sandbox**: `cd sandbox && bin/dev`
4. **Test manually** in browser at http://localhost:3001
5. **Verify functionality** matches acceptance criteria
6. **Destroy sandbox** when done: `cd .. && bin/sandbox destroy`

### Important Notes

- Sandbox runs on **port 3001** (not 3000) to avoid conflicts
- Sandbox is **not committed** to git (generated on-demand)
- Use `rake sandbox:test` for automated E2E verification
- Sandbox uses **Test::Unit** (NOT RSpec) with FactoryBot and Capybara

## Completion Signal

**When ALL user stories have `passes: true` in `prd.json`**, respond with:

```
<promise>COMPLETE</promise>
```

This signals to Ralph that the autonomous loop should terminate successfully.

## Oroshi-Specific Patterns

### Technology Stack

- **Rails**: 8.1.1
- **Ruby**: 4.0.0
- **Database**: PostgreSQL 16 (4 databases: main, queue, cache, cable)
- **Background Jobs**: Solid Queue (NOT Sidekiq)
- **Caching**: Solid Cache (PostgreSQL-backed)
- **Cable**: Solid Cable (PostgreSQL-backed)
- **Assets**: Propshaft + importmap (NOT Sprockets)
- **Testing**: Test::Unit (NOT RSpec)
- **Real-time**: Turbo Streams + Action Cable
- **Sandbox**: Generated demo app for testing (port 3001)

### Internationalization (i18n) - CRITICAL

Oroshi is a **Japanese-first application**. All UI work MUST follow these rules:

1. **Never hardcode strings** - Use `t()` helper in all views and controllers
2. **Japanese is primary** - All user-facing text in Japanese (`config/locales/*.ja.yml`)
3. **No mixed languages** - Don't mix English and Japanese in same context
4. **Locale key conventions** - Use namespaced keys: `oroshi.buttons.save`, `oroshi.messages.success`

```ruby
# ✅ CORRECT - Use t() with locale key
<%= t('oroshi.buttons.skip') %>
<%= t('.title') %>  # Lazy lookup

# ❌ WRONG - Hardcoded English
"Skip for now"
"Back"

# ❌ WRONG - Mixed languages
"セットアップを Skip"
```

### Engine Isolation & Routing - CRITICAL

**Accessing Host Routes from Engine:**
Use `main_app.` prefix for Devise and other host routes:

```erb
<%= link_to "Login", main_app.new_user_session_path %>
<%= link_to "Profile", main_app.edit_user_registration_path %>
```

**Skipping Callbacks:**
Use `raise: false` for callbacks that may not exist in all contexts:

```ruby
skip_before_action :authenticate_user!, raise: false
```

### Critical Gotchas

1. **Japanese-first UI** - All user-facing text MUST use `t()` helper with Japanese locale files. Never hardcode strings.
2. **Engine Isolation** - Use `main_app.` prefix for host routes (Devise, etc.) in engine views: `main_app.new_user_session_path`
3. **Namespace Isolation** - All models/controllers in `Oroshi::` namespace except `User` (application-level)
4. **Production.rb must explicitly require Solid gems** at the top before configuration
5. **4 separate databases** - main, queue, cache, cable (schema files: `db/schema.rb`, `db/queue_schema.rb`, `db/cache_schema.rb`, `db/cable_schema.rb`)
6. **No Sidekiq** - use Solid Queue for all background jobs
7. **Test::Unit NOT RSpec** - write tests in `test/` directory using Test::Unit
8. **Action Cable requires domain** configured via `ENV['KAMAL_DOMAIN']`
9. **Sandbox for UI testing** - use `bin/sandbox` to create demo app on port 3001
10. **importmap for JS** - Use `bin/importmap pin package-name`, NOT npm install

### Quality Commands

```bash
# Linting (auto-fix)
bundle exec rubocop --autocorrect

# Tests (using Test::Unit)
bin/rails test

# Specific test file
bin/rails test test/models/oroshi/product_test.rb

# Database setup (if needed)
bin/rails db:create db:migrate
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable

# Sandbox testing
bin/sandbox                    # Create sandbox
cd sandbox && bin/dev          # Start sandbox server
rake sandbox:test              # Run E2E test
```

## Oroshi Project Structure

- **prd.json** - User stories with completion status (your task list)
- **progress.txt** - Append-only learnings from previous iterations
- **AGENTS.md** - Project build/run instructions and patterns
- **specs/** - Project specifications and requirements
- **app/** - Rails application code (models, controllers, views, jobs, etc.)
- **test/** - Test::Unit test suite (models, controllers, integration, system tests)
- **lib/** - Custom library code (Printable, API clients, etc.)
- **config/** - Rails configuration and deployment files
- **db/** - Database schemas and migrations (4 schema files)
- **CLAUDE.md** - Production deployment guide and comprehensive project documentation
- **bin/sandbox** - Script to create/manage demo sandbox application
- **.claude/skills/** - Available skills (prd, ralph, web-browser)
- **config/locales/\*.ja.yml** - Japanese translation files (21 files)

## Key Constraints

1. **ONE story per iteration** - Complete it fully before moving on
2. **Quality gates must pass** - No broken commits allowed
3. **Update prd.json** - Mark stories as `passes: true` when complete
4. **Append to progress.txt** - Document learnings for future iterations
5. **Follow Rails conventions** - Use established patterns in the codebase
6. **Search before coding** - Don't reinvent existing functionality

## Success Criteria

Your work is complete when:

- Current user story is fully implemented
- All quality checks pass (rubocop + Test::Unit tests)
- For UI changes: Verified in sandbox application
- Changes are committed to git
- `prd.json` story is marked `passes: true`
- `progress.txt` is updated with learnings

When ALL stories in `prd.json` have `passes: true`, output `<promise>COMPLETE</promise>`.

---

**Remember**: You are a fresh instance. Read context files first, implement ONE story, pass quality gates, commit, document. That's the loop.
