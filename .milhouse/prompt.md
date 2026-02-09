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
   - Check git branch matches `branchName` from prd.json. If not, check it out or create from master.

2. **Select Task**

   - Find the highest-priority story where `passes: false`
   - Only work on ONE story per iteration
   - If all stories have `passes: true`, respond with `<promise>COMPLETE</promise>`

3. **Implement Feature**

   - Implement the single user story completely
   - Follow Rails 8 best practices and Oroshi conventions
   - Search codebase before assuming features don't exist
   - This PRD is frontend-focused: JS fixes, Stimulus controllers, view templates, CSS, and locale files

4. **Quality Checks** (MUST PASS before committing)

   - Run: `bundle exec rubocop --autocorrect` (linting)
   - Run: `bin/rails test` (tests - Test::Unit, NOT RSpec)
   - Verify no errors or failures
   - For UI/JS changes: verify in browser if Playwright MCP tools are available

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

## Current PRD Focus: Frontend Bug Fixes & UI Polish

This iteration focuses on fixing frontend issues across the engine:

### Key Areas

1. **Asset Pipeline** - CSS import fix (SCSS @import syntax)
2. **Stimulus Controllers** - Missing Bootstrap imports, action binding mismatches, namespace conflicts
3. **Modal Standardization** - Order modal must match the supply modal pattern (custom dialog controller extending @stimulus-components/dialog, native HTML5 `<dialog>` API)
4. **Locale Updates** - Replace legacy 牡蠣 (oyster) references with generic supply terms
5. **UI Polish** - Order filters responsiveness and reset functionality

### Critical Patterns for This PRD

- **Bootstrap in ES modules**: Each Stimulus controller that uses Bootstrap must `import * as bootstrap from "bootstrap"` in its own file. The import in `application.js` only creates a module-scoped variable.
- **Native `<dialog>` API**: The codebase is migrating from Bootstrap modals to native HTML5 `<dialog>` with `@stimulus-components/dialog`. The supply modal (`oroshi/supplies/dialog_controller.js`) is the reference implementation.
- **Stimulus action syntax**: Always use explicit event types: `submit->controller#method`, not just `controller#method`.
- **Turbo frame placement**: Turbo-frames should wrap modal content only, not the footer. Wrapping the footer causes dialog lifecycle conflicts.
- **Propshaft SCSS imports**: `@import "file.css"` generates a CSS `@import url()`. Remove the `.css` extension to embed the file contents.

### Reference Files

- **Supply dialog controller (working pattern)**: `app/javascript/controllers/oroshi/supplies/dialog_controller.js`
- **Supply modal view (working pattern)**: `app/views/oroshi/supplies/modal/_init_supply_modal.html.erb`
- **Order dashboard controller (needs fixes)**: `app/javascript/controllers/oroshi/orders/order_dashboard_controller.js`
- **Revenue controller (needs Bootstrap import)**: `app/javascript/controllers/oroshi/orders/revenue_controller.js`
- **Supply date input controller (needs null guards)**: `app/javascript/controllers/oroshi/supplies/supply_date_input_controller.js`

## Project-Specific Patterns

### Technology Stack

- **Rails**: 8.1.1 (Ruby 4.0.0)
- **Database**: PostgreSQL 16 (4 databases: main, queue, cache, cable)
- **Background Jobs**: Solid Queue (NOT Sidekiq)
- **Assets**: Propshaft + importmap (NOT Webpack/Sprockets)
- **Testing**: Test::Unit + FactoryBot + Capybara (NOT RSpec)
- **CSS**: Tailwind CSS + Bootstrap 5
- **Frontend**: Turbo + Stimulus
- **Authentication**: Devise
- **i18n**: Japanese-first (all UI in Japanese)

### Critical Gotchas

1. **Solid gems must load first** - `lib/oroshi/engine.rb` requires solid-* gems at the top
2. **Test::Unit, NOT RSpec** - use `assert_equal`, `assert_not_nil`, not `expect().to`
3. **Engine isolation** - all models namespaced `Oroshi::*`, all tables prefixed `oroshi_*`
4. **User model exception** - `User` is NOT namespaced (application-level)
5. **Japanese-first UI** - all user-facing text uses `t()` helper with Japanese locale files
6. **importmap for JS** - use `bin/importmap pin` to add dependencies, NOT npm install
7. **Engine routes** - use `Oroshi::Engine.routes.draw`, never `Rails.application.routes.draw`
8. **Stimulus controller naming** - directory `controllers/oroshi/orders/revenue_controller.js` auto-registers as `oroshi--orders--revenue`

### Quality Commands

```bash
# Linting (auto-fix)
bundle exec rubocop --autocorrect

# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/oroshi/order_test.rb

# Run tests for a directory
bin/rails test test/controllers/
```

## Documentation Search

Search project documentation with qmd before making changes:

```bash
qmd search "stimulus controller patterns" -c oroshi
qmd search "modal implementation" -c oroshi
qmd search "bootstrap import" -c oroshi
```

## Key Files

- **Main CLAUDE.md**: `/Users/cody/Dev/oroshi/CLAUDE.md` - Full project conventions
- **Engine**: `lib/oroshi/engine.rb` - Core engine setup
- **Routes**: `config/routes.rb` - Engine routes
- **Locales**: `config/locales/*.yml` - i18n translations
- **JS Controllers**: `app/javascript/controllers/` - Stimulus controllers
- **Importmap**: `config/importmap.rb` - JS dependency pins

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
