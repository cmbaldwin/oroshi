# Ralph Agent Instructions - Oroshi Project

## Context

You are an autonomous AI agent executing within the Ralph loop system, working on **Oroshi**, a wholesale order management system built with Ruby on Rails 8.1.1.

**IMPORTANT**: This is a fresh Amp instance. Your only memory comes from:
- Git history (previous commits)
- `progress.txt` (append-only learnings from previous iterations)
- `prd.json` (task status tracking with user stories)
- `AGENTS.md` files (codebase patterns and conventions)

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
   - Run: `bundle exec rspec` (tests - exclude system tests with `--exclude-pattern="spec/system/**/*_spec.rb"`)
   - Verify no errors or failures
   - For UI changes: Manually verify in browser if possible

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
2. **Tests**: `bundle exec rspec --exclude-pattern="spec/system/**/*_spec.rb"`
3. **No errors**: Zero failures, zero errors

**CRITICAL**: Never commit broken code. If quality checks fail, fix them first.

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
- **Testing**: RSpec
- **Real-time**: Turbo Streams + Action Cable

### Critical Gotchas
1. **Production.rb must explicitly require Solid gems** at the top before configuration
2. **4 separate databases** - main, queue, cache, cable (schema files: `db/schema.rb`, `db/queue_schema.rb`, `db/cache_schema.rb`, `db/cable_schema.rb`)
3. **No Sidekiq** - use Solid Queue for all background jobs
4. **Exclude system tests** during automated runs: `--exclude-pattern="spec/system/**/*_spec.rb"`
5. **Action Cable requires domain** configured via `ENV['KAMAL_DOMAIN']`

### Quality Commands
```bash
# Linting (auto-fix)
bundle exec rubocop --autocorrect

# Tests (exclude system tests)
bundle exec rspec --exclude-pattern="spec/system/**/*_spec.rb"

# Database setup (if needed)
bin/rails db:create db:migrate
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable
```

## Oroshi Project Structure

- **prd.json** - User stories with completion status (your task list)
- **progress.txt** - Append-only learnings from previous iterations
- **AGENTS.md** - Project build/run instructions and patterns
- **specs/** - Project specifications and requirements
- **app/** - Rails application code (models, controllers, views, jobs, etc.)
- **spec/** - RSpec test suite (models, requests, system tests)
- **lib/** - Custom library code (Printable, API clients, etc.)
- **config/** - Rails configuration and deployment files
- **db/** - Database schemas and migrations (4 schema files)
- **CLAUDE.md** - Production deployment guide

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
- All quality checks pass (rubocop + rspec)
- Changes are committed to git
- `prd.json` story is marked `passes: true`
- `progress.txt` is updated with learnings

When ALL stories in `prd.json` have `passes: true`, output `<promise>COMPLETE</promise>`.

---

**Remember**: You are a fresh Amp instance. Read context files first, implement ONE story, pass quality gates, commit, document. That's the loop.
