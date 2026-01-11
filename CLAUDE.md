# Oroshi - Rails Engine Development Guide

**Repository:** https://github.com/cmbaldwin/oroshi
**Type:** Rails Engine Gem for wholesale order management
**Rails:** 8.1.1 | **Ruby:** 4.0.0

## Project Overview

Oroshi is a Rails engine gem providing a complete wholesale order management system. It's designed to be mounted into parent Rails applications with minimal configuration, following patterns established by successful gems like Solidus and Spree.

### Key Characteristics

- **Opinionated & Complete**: Works out-of-box with sensible defaults
- **Japanese-First**: All UI, i18n, and documentation in Japanese
- **Modern Rails 8**: Uses Solid Queue, Solid Cache, Solid Cable
- **Well-Tested**: 539+ test examples with comprehensive coverage
- **Generated Sandbox**: Full demo app for testing and development

## Build & Run

### Development Setup

```bash
# Install dependencies
bundle install

# Set up databases
bin/rails db:create db:migrate

# Load Solid schemas
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable

# Start development server (not used for gem development)
./bin/dev
```

### Sandbox Application

The recommended way to develop and test Oroshi is using the generated sandbox:

```bash
# Generate sandbox application
bin/sandbox

# Start the sandbox
cd sandbox
bin/dev

# Visit: http://localhost:3000
# Sign in: admin@oroshi.local / password123
```

**Sandbox Commands:**

```bash
bin/sandbox              # Create sandbox (default)
bin/sandbox reset        # Destroy and recreate
bin/sandbox destroy      # Remove sandbox
bin/sandbox help         # Show all commands

# Use different database
DB=mysql bin/sandbox     # Create with MySQL instead of PostgreSQL
```

The sandbox is generated on-demand (not committed) following the Solidus pattern. See [docs/SANDBOX_TESTING.md](docs/SANDBOX_TESTING.md) for details.

### Testing

```bash
# Run specific test files (recommended for speed)
bin/rails test test/models/oroshi/product_test.rb
bin/rails test test/controllers/oroshi/dashboard_controller_test.rb

# Run tests for a directory
bin/rails test test/models/

# Run all tests
bin/rails test

# Run sandbox E2E test (creates sandbox, tests it, destroys it)
rake sandbox:test
```

**Testing Requirements:**

- This project uses **Test::Unit** (NOT RSpec)
- Write tests for ALL new features
- Tests go in `test/` directory mirroring `app/` structure
- Factories in `test/factories/` using FactoryBot
- All tests must pass before committing code

**Test Categories:**

- Model tests: associations, validations, public methods
- Controller tests: actions, authentication, redirects, flash messages
- Integration tests: multi-step workflows
- System tests: browser-based user journeys
- E2E tests: complete sandbox lifecycle

### Quality Checks

```bash
# Run linting
bundle exec rubocop --parallel

# Run security scanner
bundle exec brakeman --no-pager

# Run secret scanning
gitleaks detect --source . --log-level info
```

## Technology Stack

- **Rails**: 8.1.1 (Ruby 4.0.0)
- **Database**: PostgreSQL 16 (4 separate databases)
- **Background Jobs**: Solid Queue (NOT Sidekiq)
- **Caching**: Solid Cache (PostgreSQL-backed)
- **Cable**: Solid Cable (PostgreSQL-backed)
- **Assets**: Propshaft + importmap (NO Webpack/Sprockets)
- **CSS**: Tailwind CSS + Bootstrap 5
- **Frontend**: Turbo + Stimulus
- **Testing**: Test::Unit + FactoryBot + Capybara
- **Authentication**: Devise (included in gem)
- **PDF Generation**: Prawn (Japanese font support)

## Architecture

### Multi-Database Setup

Oroshi uses 4 PostgreSQL databases:

1. **oroshi_production** - Main application data (41 tables)
2. **oroshi_production_queue** - Solid Queue jobs
3. **oroshi_production_cache** - Solid Cache entries
4. **oroshi_production_cable** - Solid Cable messages

**Schema files:**

- `db/schema.rb` - Main schema
- `db/queue_schema.rb` - Queue schema
- `db/cache_schema.rb` - Cache schema
- `db/cable_schema.rb` - Cable schema

**Development database names:**

- `oroshi_development`
- `oroshi_development_queue`
- `oroshi_development_cache`
- `oroshi_development_cable`

### Engine Structure

```
oroshi/
├── lib/
│   ├── oroshi.rb                    # Main loader
│   ├── oroshi/
│   │   ├── engine.rb                # Rails::Engine (loads Solid gems first)
│   │   ├── configuration.rb         # Configuration DSL
│   │   ├── version.rb               # Gem version
│   │   └── fonts.rb                 # Font path helpers
│   ├── generators/oroshi/
│   │   └── install_generator.rb    # Main installer
│   ├── printables/                  # PDF generation
│   └── tasks/                       # Rake tasks
├── app/                             # Engine application
│   ├── models/oroshi/              # 44 models
│   ├── controllers/oroshi/         # 37 controllers
│   ├── views/oroshi/               # All views
│   ├── jobs/oroshi/                # 5 background jobs
│   ├── assets/                     # CSS, JS, images, fonts
│   └── helpers/oroshi/             # Helpers
├── db/
│   └── migrate/                    # All migrations (timestamped)
├── config/
│   ├── routes.rb                   # Engine routes
│   ├── locales/                    # Japanese i18n (21 files)
│   └── recurring.yml               # Solid Queue recurring tasks
├── test/                           # Test suite
│   ├── dummy/                      # Minimal test app
│   └── [models, controllers, integration, system]
└── sandbox/                        # Generated demo app (not committed)
```

### Namespace Isolation

- All models: `Oroshi::Order`, `Oroshi::Buyer`, etc.
- All tables: `oroshi_orders`, `oroshi_buyers`, etc.
- Engine uses `isolate_namespace Oroshi`
- User model: `User` (NOT namespaced - application-level)

## Critical Patterns

### 1. Solid Gems Loading Order (CRITICAL)

**IMPORTANT:** Solid gems MUST load before Rails configuration:

```ruby
# lib/oroshi/engine.rb
# MUST be first lines - load BEFORE Rails.application.configure
require 'solid_queue'
require 'solid_cache'
require 'solid_cable'

module Oroshi
  class Engine < ::Rails::Engine
    isolate_namespace Oroshi
    # ... rest of configuration
  end
end
```

Without explicit requires, `connected_to` will fail because Railties haven't registered the database shards.

### 2. Background Jobs (Solid Queue)

**CRITICAL**: Use Solid Queue, NOT Sidekiq

```ruby
# Good - Namespaced job
class Oroshi::MyJob < ApplicationJob
  queue_as :default

  def perform(arg)
    # Job logic
  end
end

# Enqueue
Oroshi::MyJob.perform_later(arg)
```

Start workers in development: `bin/jobs` (included in `./bin/dev`)

### 3. Asset Pipeline

Uses **Propshaft + importmap** (NOT Webpack/Sprockets):

- JavaScript: `app/javascript/` with importmap
- CSS: `app/assets/stylesheets/` with Tailwind
- Fonts: `app/assets/fonts/` (14MB Japanese fonts)
- No node_modules bundling in production

Add JS dependencies:

```bash
bin/importmap pin package-name  # NOT npm install
```

### 4. PDF Generation with Japanese Fonts

```ruby
# lib/oroshi/fonts.rb provides font path helpers
module Oroshi
  module Fonts
    def self.font_path(font_name)
      Oroshi::Engine.root.join("app/assets/fonts/#{font_name}").to_s
    end

    def self.configure_prawn_fonts(pdf)
      pdf.font_families.update(
        "NotoSans" => {
          normal: font_path("NotoSansJP-Regular.ttf"),
          bold: font_path("NotoSansJP-Bold.ttf")
        }
      )
    end
  end
end

# Usage in printables
class MyPrintable < Printable
  def initialize
    super
    Oroshi::Fonts.configure_prawn_fonts(@pdf)
  end
end
```

### 5. Configuration DSL

Parent applications configure Oroshi in `config/application.rb`:

```ruby
# config/application.rb
Oroshi.configure do |config|
  config.time_zone = "Asia/Tokyo"
  config.locale = :ja
  config.domain = ENV.fetch("DOMAIN", "localhost")
end
```

## Internationalization (i18n)

### Language Priority

Oroshi is a **Japanese-first application**. All user-facing text must:

1. **Use Japanese as the primary language** - All UI text, buttons, labels, messages in Japanese
2. **Use `t()` helper with locale files** - Never hardcode strings in views or controllers
3. **Avoid mixed languages** - Do not mix English and Japanese in the same context

### Required Practices

```ruby
# ✅ CORRECT - Use t() with locale key
<%= t('oroshi.buttons.skip') %>
<%= t('.title') %>  # Lazy lookup in views

# ❌ WRONG - Hardcoded English
"Skip for now"
"Back"
"Next"

# ❌ WRONG - Mixed languages
"セットアップを Skip"
```

### Locale File Structure

```
config/locales/
├── ja.yml                    # Main Japanese translations
├── en.yml                    # English translations (secondary)
├── oroshi.ja.yml            # Oroshi-specific Japanese
├── oroshi.hints.ja.yml      # Form hints in Japanese
└── models.ja.yml            # ActiveRecord model translations
```

### Translation Keys Convention

```yaml
ja:
  oroshi:
    common:
      buttons:
        save: "保存"
        cancel: "キャンセル"
        back: "戻る"
        next: "次へ"
        skip: "スキップ"
      confirmations:
        are_you_sure: "よろしいですか？"
    onboarding:
      buttons:
        skip_for_now: "今はスキップ"
      messages:
        skip_confirm: "オンボーディングをスキップしますか？"
```

### When Adding New UI Text

1. Add the Japanese translation to the appropriate locale file first
2. Use the `t()` helper in the view/controller
3. Never commit hardcoded strings in user-facing code

## Recurring Tasks

Oroshi uses Solid Queue's recurring task scheduler. Tasks are defined in `config/recurring.yml`:

```yaml
production:
  mail_check_and_send:
    class: Oroshi::MailerJob
    schedule: every 10 minutes

  # Add other recurring tasks here
```

### Important Notes

- All recurring tasks should use job classes (not `command` eval)
- Specify timezone explicitly: `every 1 day at 12:00 Asia/Tokyo`
- Jobs are timezone-aware (application timezone: Asia/Tokyo)

## Timezone Configuration

**Server:** UTC (recommended for Docker containers)
**Rails Application:** Asia/Tokyo

Rails automatically converts times between UTC (database) and Asia/Tokyo (application):

```ruby
# config/application.rb
config.time_zone = "Asia/Tokyo"
config.active_record.default_timezone = :utc
```

## Common Gotchas

1. **Solid Queue Configuration**: Ensure `config/recurring.yml` exists and is properly configured
2. **Multiple Databases**: Migrations go to main DB by default; use specific connection for queue/cache/cable
3. **Engine.rb**: Must explicitly require solid-* gems at the top before configuration
4. **importmap**: Use `bin/importmap pin` to add JS dependencies, not npm install
5. **User Model**: NOT namespaced under Oroshi (application-level model)
6. **Bootsnap**: Optional dependency, must handle gracefully in generated apps
7. **Japanese Fonts**: 14MB font files must be included in gem, use `Oroshi::Fonts` helper

## Troubleshooting

### Solid Queue Not Starting

**Symptoms:** Worker container starts but no job processing

**Diagnosis:**

```bash
# Check worker logs
bin/rails runner 'puts SolidQueue::Process.all.pluck(:name, :state)'

# Verify queue database has tables
bin/rails dbconsole -d queue
\dt
```

**Solutions:**

1. Check recurring.yml is valid YAML
2. Verify queue database has tables
3. Manually load queue schema: `bin/rails db:schema:load:queue`
4. Check logs for Railtie loading errors

### Turbo Streams Not Working

**Symptoms:** Real-time updates not appearing, WebSocket errors

**Solutions:**

1. Verify `lib/oroshi/engine.rb` has explicit `require 'solid_cable'` at top
2. Check cable database exists and has tables
3. Look for "No unique index found for id" errors in logs
4. Manually load cable schema if needed

### Database Connection Issues

**Symptoms:** App fails to connect to database

**Solutions:**

1. Verify all 4 databases exist (main, queue, cache, cable)
2. Check `config/database.yml` matches database names
3. Ensure environment variables are set correctly

### Sandbox Creation Fails

**Symptoms:** `bin/sandbox` exits with error

**Solutions:**

1. Check Rails is installed: `rails -v`
2. Verify PostgreSQL/MySQL is running
3. Check disk space available
4. Run manually with debug: `bash -x bin/sandbox`

## Ralph - Autonomous Development Workflow

### Overview

Ralph is an autonomous AI development agent that incrementally implements features from Product Requirements Documents (PRDs) stored in `scripts/ralph/prd.json`.

### Quick Start

1. **Review Current Tasks:**

   ```bash
   cat scripts/ralph/prd.json | jq '.userStories[] | select(.passes == false) | {id, title, priority}'
   ```

2. **Start Working:**
   Open VS Code and invoke Copilot Chat. Ralph will automatically:

   - Read `prd.json` for incomplete tasks
   - Read `progress.txt` for learnings from previous work
   - Select the highest-priority incomplete story
   - Implement it completely
   - Run quality checks (rubocop + tests)
   - Commit if all checks pass
   - Update prd.json and progress.txt

3. **Monitor Progress:**

   ```bash
   # View completed stories
   cat scripts/ralph/prd.json | jq '.userStories[] | select(.passes == true) | .title'

   # View recent learnings
   tail -n 50 scripts/ralph/progress.txt
   ```

### Ralph's Custom Instructions

Ralph operates according to custom instructions defined in:

- `.github/copilot-instructions.md` - Main Ralph instructions (workspace-wide)
- `CLAUDE.md` (this file) - Oroshi-specific patterns and conventions
- `scripts/ralph/prd.json` - Task tracking with user stories
- `scripts/ralph/progress.txt` - Append-only learning journal

### Key Ralph Behaviors

1. **One Story Per Session** - Ralph completes one user story fully before moving on
2. **Quality First** - All changes must pass linting and tests before committing
3. **Search Before Coding** - Ralph searches the codebase for existing patterns
4. **Document Learnings** - After each story, Ralph updates progress.txt

### Quality Gates

Ralph enforces these checks before marking any story complete:

```bash
# 1. Linting
bundle exec rubocop --autocorrect

# 2. Tests
bin/rails test

# 3. No failures
```

### Git Commit Format

Ralph commits use this format:

```
<type>: <description>

Co-Authored-By: Ralph (Autonomous Agent) <ralph@example.com>
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

### Working with Ralph

**To have Ralph work on the current PRD:**

1. Open VS Code
2. Start a Copilot Chat session
3. Say "Start working on the PRD" or just "Go"
4. Ralph will automatically select and implement the next incomplete story

**To check Ralph's progress:**

```bash
# View completion status
cat scripts/ralph/progress.txt

# View remaining tasks
cat scripts/ralph/prd.json | jq '.userStories[] | select(.passes == false)'
```

### Available Skills

Ralph has access to specialized skills in `.claude/skills/`:

- **prd** - Generate Product Requirements Documents with structured user stories
- **ralph** - Convert markdown PRDs to `prd.json` format for autonomous execution
- **web-browser** - Remote control Chrome/Chromium to verify UI changes

Skills automatically activate based on context and trigger phrases.

### PRD Structure

Each PRD (`prd.json`) contains:

- `project` - Project name
- `branchName` - Git branch for this work
- `description` - Overall feature description
- `userStories` - Array of stories with:
  - `id` - Unique identifier (e.g., "US-001")
  - `title` - Short story title
  - `description` - User story in "As a... I want... So that..." format
  - `acceptanceCriteria` - Array of specific requirements
  - `priority` - Order of implementation (1 = highest)
  - `passes` - Boolean, set to `true` when complete
  - `notes` - Additional context or learnings

### Files Reference

- `.github/copilot-instructions.md` - Ralph's core instructions
- `CLAUDE.md` (this file) - Oroshi patterns and conventions
- `scripts/ralph/prd.json` - Current task tracking
- `scripts/ralph/progress.txt` - Learning journal
- `scripts/ralph/prompt.md` - Legacy prompt (for reference)

## Project File Structure

```
app/
  controllers/oroshi/        # Namespaced controllers
  models/oroshi/            # Namespaced models (except User)
  views/oroshi/             # Views for Oroshi namespace
  jobs/oroshi/              # Background jobs
  mailers/oroshi/           # Mailers
  javascript/               # Stimulus controllers
  assets/
    stylesheets/            # CSS files
    fonts/                  # Japanese fonts (14MB)

config/
  application.rb            # Main Rails config
  database.yml              # 4 database connections
  recurring.yml             # Solid Queue recurring tasks
  routes.rb                 # Engine routes (namespace :oroshi)
  locales/                  # i18n files (21 files)

db/
  migrate/                  # Migrations
  schema.rb                 # Main DB schema
  queue_schema.rb           # Queue schema
  cache_schema.rb           # Cache schema
  cable_schema.rb           # Cable schema

lib/
  oroshi.rb                 # Main gem loader
  oroshi/
    engine.rb               # Rails engine (loads Solid gems first)
    configuration.rb        # Config DSL
    fonts.rb                # Font helpers
  generators/oroshi/
    install_generator.rb    # Installation generator
  printables/               # PDF generation library
  tasks/                    # Rake tasks

test/                       # Test suite (Test::Unit)
  dummy/                    # Minimal test app
  factories/                # FactoryBot factories
  models/                   # Model tests
  controllers/              # Controller tests
  integration/              # Integration tests
  system/                   # System tests
  sandbox_e2e_test.rb       # E2E sandbox test

sandbox/                    # Generated demo app (not committed)
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
- Review [README.md](README.md) for installation and usage
- Check [docs/SANDBOX_TESTING.md](docs/SANDBOX_TESTING.md) for sandbox details

## Deployment

**Note:** Deployment configuration should be set up in your parent application. Oroshi is a Rails engine gem and does not include deployment tooling.

For production deployment, configure your parent app with your preferred deployment strategy (Kamal, Capistrano, Heroku, etc.).

**Key requirements for production:**

- PostgreSQL 16 with 4-database setup (primary, queue, cache, cable)
- Background job processing (Solid Queue)
- Asset compilation (Tailwind CSS + Propshaft)
- Email delivery (configure Action Mailer)
- File storage (configure Active Storage)

## Resources

- **README**: [README.md](README.md) - Installation and usage
- **Sandbox Testing**: [docs/SANDBOX_TESTING.md](docs/SANDBOX_TESTING.md)
- **Sandbox Research**: [docs/archives/SANDBOX_RESEARCH.md](docs/archives/SANDBOX_RESEARCH.md)
- **Ralph Instructions**: [.github/copilot-instructions.md](.github/copilot-instructions.md)
- **PRD Tasks**: [scripts/ralph/prd.json](scripts/ralph/prd.json)

---

**Last Updated:** January 11, 2026
**Rails Version:** 8.1.1
**Ruby Version:** 4.0.0
**Test Coverage:** 539+ examples
