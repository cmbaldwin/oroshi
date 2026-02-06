# Milhouse Agent Instructions - Oroshi Engine

## Context

You are an autonomous AI agent executing within the Milhouse loop system, working on **Oroshi**, a Rails 8.1.1 engine gem for wholesale order management.

**IMPORTANT**: This is a fresh agent instance. Your only memory comes from:

- Git history (previous commits)
- `progress.txt` (append-only learnings from previous iterations)
- `prd.json` (task status tracking with user stories)
- `CLAUDE.md` (project-specific patterns and conventions)

## Workflow for Each Iteration

1. **Read Context Files**

   - Read `prd.json` to see all user stories and their completion status
   - Read `progress.txt` to learn from previous iterations
   - Read `CLAUDE.md` for project conventions and critical patterns
   - Check git branch matches the current story

2. **Select Task**

   - Find the highest-priority story where `passes: false`
   - Only work on ONE story per iteration
   - If all stories have `passes: true`, respond with `<promise>COMPLETE</promise>`

3. **Implement Feature**

   - Implement the single user story completely
   - Follow Rails 8 best practices and Oroshi conventions
   - Search codebase before assuming features don't exist

4. **Quality Checks** (MUST PASS before committing)

   - Run: `bundle exec rubocop --autocorrect` (linting)
   - Run: `bin/rails test` (tests - Test::Unit, NOT RSpec)
   - Verify no errors or failures
   - For UI changes: manually verify in browser if possible

5. **Commit Changes**

   - Commit ONLY if all quality checks pass
   - Use format: `feat: <story description>` or `fix: <story description>`
   - Include Co-authored-by: `Co-Authored-By: Milhouse (Autonomous Agent) <milhouse@example.com>`

6. **Update Documentation**
   - Update story in `prd.json` to `passes: true` if complete
   - Append to `progress.txt` with timestamped entry (see format below)

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

## Quality Gates (MUST PASS)

All commits require passing:

1. **Linting**: `bundle exec rubocop --autocorrect`
2. **Tests**: `bin/rails test` (Test::Unit with FactoryBot)
3. **No errors**: Zero failures, zero errors

**CRITICAL**: Never commit broken code. If quality checks fail, fix them first.

## Completion Signal

**When ALL user stories have `passes: true` in `prd.json`**, respond with:

```
<promise>COMPLETE</promise>
```

This signals to Milhouse that the autonomous loop should terminate successfully.

## Project-Specific Patterns

### Technology Stack

- **Rails**: 8.1.1 (Ruby 4.0.0)
- **Database**: PostgreSQL 16 (4 databases: main, queue, cache, cable)
- **Background Jobs**: Solid Queue (NOT Sidekiq)
- **Caching**: Solid Cache (PostgreSQL-backed)
- **Cable**: Solid Cable (PostgreSQL-backed)
- **Assets**: Propshaft + importmap (NOT Webpack/Sprockets)
- **Testing**: Test::Unit + FactoryBot + Capybara (NOT RSpec)
- **Real-time**: Turbo Streams + Action Cable
- **CSS**: Tailwind CSS + Bootstrap 5
- **Authentication**: Devise
- **PDF**: Prawn with Japanese font support
- **i18n**: Japanese-first (all UI in Japanese)

### Critical Gotchas

1. **Solid gems must load first** - `lib/oroshi/engine.rb` requires solid-* gems at the top before Rails configuration
2. **4 separate databases** - main, queue, cache, cable (schema files: `db/schema.rb`, `db/queue_schema.rb`, `db/cache_schema.rb`, `db/cable_schema.rb`)
3. **No Sidekiq** - use Solid Queue for all background jobs
4. **Test::Unit, NOT RSpec** - use `assert_equal`, `assert_not_nil`, not `expect().to`
5. **Engine isolation** - all models namespaced `Oroshi::*`, all tables prefixed `oroshi_*`
6. **User model exception** - `User` is NOT namespaced (application-level)
7. **Japanese-first UI** - all user-facing text uses `t()` helper with Japanese locale files
8. **Factory naming** - factories are named `oroshi_order`, `oroshi_buyer`, etc. (prefixed)
9. **importmap for JS** - use `bin/importmap pin` to add dependencies, NOT npm install
10. **Engine routes** - use `Oroshi::Engine.routes.draw`, never `Rails.application.routes.draw`

### Quality Commands

```bash
# Linting (auto-fix)
bundle exec rubocop --autocorrect

# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/oroshi/order_test.rb

# Run tests for a directory
bin/rails test test/jobs/

# Database setup (if needed)
bin/rails db:create db:migrate
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable
```

### Factory Patterns

```ruby
# Factory definition (in test/factories/oroshi/*.rb)
FactoryBot.define do
  factory :oroshi_order, class: "Oroshi::Order" do
    # attributes
  end
end

# Usage in tests
create(:oroshi_order)
build(:oroshi_buyer)
```

### Test File Structure

```
# Tests mirror app structure
app/jobs/oroshi/mailer_job.rb     → test/jobs/oroshi/mailer_job_test.rb
app/models/oroshi/order.rb        → test/models/oroshi/order_test.rb
app/controllers/oroshi/orders_controller.rb → test/controllers/oroshi/orders_controller_test.rb
```

## Documentation Search

Search project documentation with qmd before making changes:

```bash
qmd search "factory patterns" -c oroshi
qmd search "solid queue configuration" -c oroshi
qmd search "engine routing" -c oroshi
```

## Key Files

- **Main CLAUDE.md**: `/Users/cody/Dev/oroshi/CLAUDE.md` - Full project conventions
- **Test Helper**: `test/test_helper.rb` - Test configuration
- **Factories**: `test/factories/oroshi/*.rb` - All FactoryBot factories
- **Engine**: `lib/oroshi/engine.rb` - Core engine setup
- **Routes**: `config/routes.rb` - Engine routes
- **Locales**: `config/locales/*.yml` - i18n translations

## Key Constraints

1. **ONE story per iteration** - Complete it fully before moving on
2. **Quality gates must pass** - No broken commits allowed
3. **Update prd.json** - Mark stories as `passes: true` when complete
4. **Append to progress.txt** - Document learnings for future iterations
5. **Follow project conventions** - Use established patterns in the codebase
6. **Search before coding** - Don't reinvent existing functionality
7. **Japanese-first** - All UI text must use i18n with Japanese translations

## Success Criteria

Your work is complete when:

- Current user story is fully implemented
- All quality checks pass (rubocop + tests)
- Changes are committed to git
- `prd.json` story is marked `passes: true`
- `progress.txt` is updated with learnings

When ALL stories in `prd.json` have `passes: true`, output `<promise>COMPLETE</promise>`.

---

**Remember**: You are a fresh agent instance. Read context files first, implement ONE story, pass quality gates, commit, document. That's the loop.
