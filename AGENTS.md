# Oroshi - Agent Development Guide

This file provides patterns and conventions for AI agents working on the Oroshi wholesale order management system.

## Project Overview

Oroshi is a Rails 8.1.1 application for wholesale order management. It uses modern Rails patterns with solid-\* gems for background jobs, caching, and real-time features.

## Build & Run

### Development Server

```bash
./bin/dev          # Start Foreman with all services
./bin/rails s      # Start just the Rails server
```

### Testing

```bash
# Run specific test files (recommended for speed)
bin/rails test test/models/oroshi/product_test.rb
bin/rails test test/controllers/oroshi/dashboard_controller_test.rb

# Run tests for a directory
bin/rails test test/models/

# Run all quality checks (secret scan + linting + security + tests)
./.kamal/hooks/pre-build

# Run secret scanning only
gitleaks detect --source . --log-level info
ggshield secret scan repo . --exit-zero

# Run linting only
bundle exec rubocop --autocorrect
```

**Testing Requirements:**

- This project uses Test::Unit (NOT RSpec)
- Write tests for ALL new features before marking stories complete
- Tests go in `test/` directory mirroring `app/` structure
- Factories in `test/factories/` using FactoryBot
- Model tests: test associations, validations, and all public methods
- Controller tests: test all actions, authentication, redirects, flash messages
- Integration tests: test multi-step workflows
- All tests must pass before committing code

### Database Commands

```bash
# Create/migrate all databases (main, queue, cache, cable)
bin/rails db:create db:migrate

# Load Solid schemas
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable

# Reset database (CAUTION: destroys data)
bin/rails db:reset
```

## Technology Stack

- **Rails**: 8.1.1 (Ruby 4.0.0)
- **Database**: PostgreSQL 16 (4 separate databases)
- **Background Jobs**: Solid Queue (NOT Sidekiq)
- **Caching**: Solid Cache (PostgreSQL-backed)
- **Cable**: Solid Cable (PostgreSQL-backed)
- **Assets**: Propshaft + importmap (NO Webpack/Sprockets)
- **Testing**: RSpec + FactoryBot
- **Frontend**: Turbo + Stimulus + Bootstrap 5

## Critical Patterns

### 1. Multi-Database Setup

Oroshi uses 4 PostgreSQL databases:

- `oroshi_development` - Main application data
- `oroshi_development_queue` - Solid Queue jobs
- `oroshi_development_cache` - Solid Cache entries
- `oroshi_development_cable` - Solid Cable messages

Schema files:

- `db/schema.rb` - Main schema
- `db/queue_schema.rb` - Queue schema
- `db/cache_schema.rb` - Cache schema
- `db/cable_schema.rb` - Cable schema

### 2. Background Jobs (Solid Queue)

**CRITICAL**: Use Solid Queue, NOT Sidekiq

```ruby
# Good
class MyJob < ApplicationJob
  queue_as :default

  def perform(arg)
    # Job logic
  end
end

# Enqueue
MyJob.perform_later(arg)
```

Start workers: `bin/jobs` (included in `./bin/dev`)

### 3. Namespacing

Most models/controllers are namespaced under `Oroshi::`:

```ruby
class Oroshi::Product < ApplicationRecord
  # Model logic
end
```

### 4. Asset Pipeline

Uses **Propshaft + importmap** (NOT Webpack/Sprockets):

- JavaScript: `app/javascript/` with importmap
- CSS: `app/assets/stylesheets/` with Propshaft
- No node_modules bundling in production

### 5. Testing Conventions

- Use RSpec (not Minitest)
- Exclude system tests during CI: `--exclude-pattern="spec/system/**/*_spec.rb"`
- Use FactoryBot for test data
- Test files mirror app structure: `spec/models/oroshi/product_spec.rb`

## Common Gotchas

1. **Solid Queue Configuration**: Ensure `config/queue.yml` exists and is properly configured
2. **Multiple Databases**: Migrations go to main DB by default; use specific connection for queue/cache/cable
3. **Production.rb**: Must explicitly require solid-\* gems at the top before configuration
4. **Action Cable**: Requires `ENV['KAMAL_DOMAIN']` in production
5. **importmap**: Use `bin/importmap pin` to add JS dependencies, not npm install

## Ralph Workflow Integration

When working as Ralph (autonomous agent):

1. Check `scripts/ralph/prd.json` for tasks
2. Read `scripts/ralph/progress.txt` for learnings
3. Implement ONE story at a time
4. Run quality gates (rubocop + rspec)
5. Update prd.json and progress.txt after completion

See `.github/copilot-instructions.md` for full Ralph instructions.

### Available Skills

Ralph has access to specialized skills in `.claude/skills/`:

- **prd** - Generate Product Requirements Documents with structured user stories
- **ralph** - Convert markdown PRDs to `prd.json` format for autonomous execution
- **web-browser** - Remote control Chrome/Chromium to verify UI changes (required for UI stories)

Skills automatically activate based on context and trigger phrases. See `.claude/skills/README.md` for details.

## Project Structure

```
app/
  controllers/oroshi/        # Namespaced controllers
  models/oroshi/            # Namespaced models
  views/oroshi/             # Views for Oroshi namespace
  jobs/oroshi/              # Background jobs
  mailers/oroshi/           # Mailers
  javascript/               # Stimulus controllers
  assets/stylesheets/       # CSS files

config/
  application.rb            # Main Rails config
  database.yml              # 4 database connections
  queue.yml                 # Solid Queue config
  cache.yml                 # Solid Cache config
  cable.yml                 # Solid Cable config
  routes.rb                 # Routes (namespace :oroshi)

db/
  migrate/                  # Migrations
  schema.rb                 # Main DB schema
  queue_schema.rb           # Queue schema
  cache_schema.rb           # Cache schema
  cable_schema.rb           # Cable schema

spec/                       # RSpec tests
scripts/ralph/              # Ralph agent files
  prd.json                  # Task tracking
  progress.txt              # Learning journal
  prompt.md                 # Agent instructions
```

## Getting Help

- Check this file for patterns
- Search codebase for similar implementations
- Review `scripts/ralph/progress.txt` for past learnings
- Check Rails 8 guides for modern patterns
- Ask the team when truly blocked

## Resources

- Production deployment: `claude.md`
- Project specs: `specs/PROJECT_OVERVIEW.md`
- Ralph instructions: `.github/copilot-instructions.md`
- PRD tasks: `scripts/ralph/prd.json`
