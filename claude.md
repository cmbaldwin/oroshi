# Oroshi - Production Deployment Guide

**Application:** Oroshi Wholesale Order Management System
**Repository:** https://github.com/cmbaldwin/oroshi

## Infrastructure

- **Deployment:** Kamal 2 to your server (configured via `KAMAL_HOST`)
- **Rails:** 8.1.1 | **Ruby:** 4.0.0
- **Database:** PostgreSQL 16 (4 databases: main, queue, cache, cable)
- **Background Jobs:** Solid Queue (4 processes: Supervisor, Dispatcher, Worker, Scheduler)
- **Caching:** Solid Cache | **Cable:** Solid Cable
- **Assets:** Propshaft + importmap | **Storage:** GCS | **Email:** Resend
- **Registry:** AWS ECR (configured via `AWS_ECR_REGISTRY`)
- **Domain:** Configured via `KAMAL_DOMAIN` (Cloudflare SSL)

## Container Architecture

- `oroshi-web` - Puma web server (port 3000)
- `oroshi-workers` - Solid Queue background jobs (bin/jobs)
- `oroshi-db` - PostgreSQL 16
- `oroshi-db_backup` - Automated backups (prodrigestivill/postgres-backup-local:16)
- `oroshi-db_backup_gcs_sync` - GCS sync (google/cloud-sdk:alpine)

## Production Deployment

### Initial Setup

1. **Set up environment variables:**

   Copy `.env.example` to your environment and configure all required variables:

   ```bash
   # Required deployment variables
   export KAMAL_HOST=your.server.ip.address
   export KAMAL_DOMAIN=your-domain.com
   export AWS_ECR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com
   export GCS_CREDENTIALS_FILE=gcs-credentials.json

   # Optional: Configure 1Password for secret management
   export ONEPASSWORD_ACCOUNT_ID=your_account_id
   export ONEPASSWORD_VAULT=Oroshi/Production
   ```

   See `.env.example` for a complete list of all environment variables.

2. **Store secrets in 1Password:**

   The `.kamal/secrets` file is configured to fetch secrets from 1Password. Store the following in your vault:

   - `SECRET_KEY_BASE`
   - `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`
   - `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`
   - `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`
   - `POSTGRES_PASSWORD`
   - `CLOUDFLARE_SSL_CERT_PEM`
   - `CLOUDFLARE_SSL_KEY_PEM`
   - `GCLOUD_BUCKET`
   - `GCLOUD_PROJECT`
   - `DEVISE_KEY`
   - `MAIL_SENDER`
   - `RESEND_API_KEY`

3. **Deploy:**

   ```bash
   kamal setup
   kamal deploy
   ```

4. **Monitor:**
   ```bash
   kamal app logs -f
   kamal app logs --roles workers -f
   ```

## Database Management

### Multi-Database Architecture

Oroshi uses a 4-database PostgreSQL setup:

1. **oroshi_production** - Main application data (41 tables)
2. **oroshi_production_queue** - Solid Queue jobs
3. **oroshi_production_cache** - Solid Cache entries
4. **oroshi_production_cable** - Solid Cable messages

### Database Initialization

After setting up a new database server:

```bash
# Run migrations
kamal app exec "bin/rails db:create db:migrate"

# Initialize Solid schemas
kamal app exec "bin/rails db:schema:load:queue"
kamal app exec "bin/rails db:schema:load:cache"
kamal app exec "bin/rails db:schema:load:cable"
```

### Manual Solid Schema Loading

If automatic schema loading fails, load manually:

```bash
kamal app exec -i bash

# Inside container:
bin/rails runner "
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    database: 'oroshi_production_queue',
    username: ENV['POSTGRES_USER'],
    password: ENV['POSTGRES_PASSWORD'],
    host: ENV['DB_HOST'],
    port: ENV['DB_PORT']
  )
  load 'db/queue_schema.rb'
  puts 'Queue schema loaded!'
"

bin/rails runner "
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    database: 'oroshi_production_cache',
    username: ENV['POSTGRES_USER'],
    password: ENV['POSTGRES_PASSWORD'],
    host: ENV['DB_HOST'],
    port: ENV['DB_PORT']
  )
  load 'db/cache_schema.rb'
  puts 'Cache schema loaded!'
"

bin/rails runner "
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    database: 'oroshi_production_cable',
    username: ENV['POSTGRES_USER'],
    password: ENV['POSTGRES_PASSWORD'],
    host: ENV['DB_HOST'],
    port: ENV['DB_PORT']
  )
  load 'db/cable_schema.rb'
  puts 'Cable schema loaded!'
"

exit
kamal app boot --roles workers
```

**Why manual loading may be needed:**

- `bin/rails db:schema:load:queue` can fail with multi-database configuration issues
- `bin/docker-entrypoint` schema loading may fail silently via `connected_to`
- Direct `establish_connection` + `load` is the most reliable method

### Database Verification

```bash
# List all databases
kamal app exec "psql -U oroshi -d postgres -c '\l'" | grep oroshi

# Check table counts
kamal app exec "psql -U oroshi -d oroshi_production -c '\dt'" | wc -l
kamal app exec "psql -U oroshi -d oroshi_production_queue -c '\dt'" | wc -l

# Check Solid Queue processes
kamal app logs --roles workers --lines 30 | grep "Started"
# Should show: Supervisor, Dispatcher, Worker, Scheduler
```

## Monitoring & Operations

### Application Logs

```bash
# Web server logs
kamal app logs -f

# Worker logs
kamal app logs --roles workers -f

# Specific container logs
kamal app logs -f --limit 100
```

### Health Checks

```bash
# Application health
curl https://your-domain.com/up

# Rails console
kamal app exec -i "bin/rails console"

# Solid Queue status
kamal app exec -i "bin/rails runner 'puts SolidQueue::Process.count'"

# Check job queue
kamal app exec -i "bin/rails runner 'puts \"Queued: #{SolidQueue::Job.count}, Failed: #{SolidQueue::FailedExecution.count}\"'"
```

### Database Console

```bash
# Forward database port
kamal accessory forward db --local-port 5432

# Connect with psql
psql -h localhost -p 5432 -U oroshi -d oroshi_production

# Or use Rails dbconsole
kamal app exec -i "bin/rails dbconsole"
```

## Critical Configuration Notes

### Production.rb Must Load Solid Gems First

**IMPORTANT:** Explicitly require Solid gems before Rails configuration:

```ruby
# config/environments/production.rb

# CRITICAL: Load Solid gems first to ensure Railties register
require 'solid_queue'
require 'solid_cache'
require 'solid_cable'

Rails.application.configure do
  # ... rest of configuration
end
```

Without explicit requires, `connected_to` will fail because Railties haven't registered the database shards.

### Asset Pipeline (Propshaft)

- No `config.assets.*` settings needed (those are Sprockets-only)
- importmap.rb uses CDN URLs for JavaScript libraries
- sassc-rails compiles SCSS, Propshaft serves digested assets

### Development vs Production

**Development:**

- Single database (oroshi_development)
- In-memory adapters (async/memory_store)
- No worker container needed

**Production:**

- 4 databases (main + queue + cache + cable)
- Solid adapters (PostgreSQL-backed)
- Dedicated worker container

## Environment Variables

All environment variables are documented in [`.env.example`](.env.example). Copy this file and configure for your environment.

### Required Deployment Variables

These must be set before deploying:

```bash
# Deployment configuration
KAMAL_HOST=your.server.ip.address
KAMAL_DOMAIN=your-domain.com
AWS_ECR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com
GCS_CREDENTIALS_FILE=gcs-credentials.json
```

### Required Secrets (stored in 1Password)

The `.kamal/secrets` file fetches these from 1Password:

```bash
# Core Rails
SECRET_KEY_BASE=your-secret-key
RAILS_MASTER_KEY=your-master-key

# Active Record Encryption
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=your-key
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=your-key
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=your-salt

# Database
POSTGRES_PASSWORD=your-secure-password

# Email (Resend)
RESEND_API_KEY=re_your_api_key
MAIL_SENDER=noreply@yourdomain.com

# Google Cloud Storage
GCLOUD_PROJECT=your-project-id
GCLOUD_BUCKET=your-bucket-name
GBUCKET_PREFIX=oroshi-db-backups

# Authentication
DEVISE_KEY=your-devise-secret

# SSL (Cloudflare origin certificates)
CLOUDFLARE_SSL_CERT_PEM=-----BEGIN CERTIFICATE-----...
CLOUDFLARE_SSL_KEY_PEM=-----BEGIN PRIVATE KEY-----...
```

For a complete list with descriptions, see [`.env.example`](.env.example).

## Database Backups

### Automated Backup System

Oroshi includes automated PostgreSQL backups with GCS sync:

```bash
# Create manual backup
kamal app exec "bin/rails db:backup:create"

# List available backups
kamal app exec "bin/rails db:backup:list"

# Check backup status
kamal accessory logs db_backup
kamal accessory logs db_backup_gcs_sync
```

### Backup Configuration

- **Schedule:** Daily at midnight UTC (automated via cron)
- **Retention:** 7 days (daily) + 4 weeks (weekly) + 6 months (monthly)
- **Storage:** Local volume + Google Cloud Storage
- **Location:** `gs://your-bucket/db-backups/`

### Backup Containers

Two containers handle backups:

1. **oroshi-db_backup** - Creates PostgreSQL dumps

   - Image: `prodrigestivill/postgres-backup-local:16`
   - Schedule: `@daily`
   - Retention policy enforced automatically

2. **oroshi-db_backup_gcs_sync** - Syncs to GCS
   - Image: `google/cloud-sdk:alpine`
   - Schedule: Hourly
   - Requires GCS credentials

### Backup Restoration

**WARNING:** This will overwrite production data!

```bash
# Download backup from GCS
gsutil cp gs://your-bucket/db-backups/backup-name.sql.gz ./

# Stop application
kamal app stop

# Restore database
gunzip -c backup-name.sql.gz | kamal app exec -i "psql -U oroshi -d oroshi_production"

# Restart application
kamal deploy
```

## Testing

### Test Suite

Current status: 539 examples, 0 failures, 6 pending

### Pre-Deployment Testing

The Kamal pre-build hook automatically runs tests:

```bash
# Runs automatically on deploy:
kamal deploy

# Or manually:
bundle exec rspec --exclude-pattern="spec/system/**/*_spec.rb" spec/
```

To skip tests during deployment:

```bash
SKIP_TESTS=true kamal deploy
```

### Manual Testing

Some features require manual testing:

- PDF generation (invoices, packing lists, supply checks)
- Email delivery
- Real-time WebSocket updates (Turbo Streams)
- Multi-user supply entry

## Recurring Tasks

Oroshi uses Solid Queue's recurring task scheduler. Tasks are defined in `config/recurring.yml`:

```yaml
production:
  mail_check_and_send:
    class: Oroshi::MailerJob
    schedule: every 10 minutes

  # Add other recurring tasks here
```

### View Recurring Tasks

```bash
# List configured tasks
kamal app exec -i "bin/rails runner 'puts SolidQueue::RecurringTask.pluck(:key, :schedule).join(\"\n\")'"

# Check scheduler process
kamal app logs --roles workers | grep -i scheduler
```

### Important Notes

- All recurring tasks should use job classes (not `command` eval)
- Specify timezone explicitly in schedule: `every 1 day at 12:00 Asia/Tokyo`
- Jobs are timezone-aware (application timezone: Asia/Tokyo)

## Timezone Configuration

**Server:** UTC (recommended for Docker containers)
**Rails Application:** Asia/Tokyo (configurable in config/application.rb)

Rails automatically converts times between UTC (database) and Asia/Tokyo (application):

```ruby
# config/application.rb
config.time_zone = "Asia/Tokyo"
config.active_record.default_timezone = :utc
```

Verify timezone settings:

```bash
# Container timezone
kamal app exec "date && cat /etc/timezone"

# Rails timezone
kamal app exec "bin/rails runner 'puts Time.zone.name'"
```

## Troubleshooting

### Solid Queue Not Starting

**Symptoms:** Worker container starts but no job processing

**Diagnosis:**

```bash
kamal app logs --roles workers
kamal app exec "psql -U oroshi -d oroshi_production_queue -c '\dt'"
```

**Solutions:**

1. Check worker logs for errors
2. Verify queue database has tables
3. Manually load queue schema (see Database Management section)
4. Restart worker container: `kamal app stop --roles workers && kamal app start --roles workers`

### Turbo Streams Not Working

**Symptoms:** Real-time updates not appearing, WebSocket errors

**Diagnosis:**

```bash
# Check for Railtie loading errors
kamal app logs | grep -i "railtie\|cable"

# Verify cable database
kamal app exec "psql -U oroshi -d oroshi_production_cable -c '\dt'"
```

**Solutions:**

1. Verify production.rb has explicit `require 'solid_cable'` at top
2. Check cable database exists and has tables
3. Look for "No unique index found for id" errors in logs
4. Manually load cable schema if needed

### Database Connection Issues

**Symptoms:** App fails to connect to database

**Diagnosis:**

```bash
# Check database container
kamal accessory logs db

# Check connectivity from web container
kamal app exec "psql -U oroshi -d postgres -c '\l'"
```

**Solutions:**

1. Verify all 4 databases exist (main, queue, cache, cable)
2. Check environment variables are set correctly
3. Verify database.yml matches database names
4. Ensure DB_HOST points to correct container name

### Failed Background Jobs

**Symptoms:** Jobs failing repeatedly

**Diagnosis:**

```bash
# View recent failures
kamal app exec -i "bin/rails runner '
  SolidQueue::FailedExecution.last(10).each do |f|
    puts \"#{f.job.class_name}: #{f.error.message}\"
    puts f.error.backtrace.first(5).join(\"\n\")
    puts \"---\"
  end
'"
```

**Solutions:**

1. Review error messages and stack traces
2. Check for missing environment variables
3. Verify external service credentials (email, storage, etc.)
4. Retry failed jobs: `kamal app exec "bin/rails runner 'SolidQueue::Job.retry_all'"`

## Production Checklist

Before deploying to production:

- [ ] Configure `.kamal/secrets` with all required environment variables
- [ ] Set up database backup system with GCS credentials
- [ ] Configure SSL certificates (Cloudflare or Let's Encrypt)
- [ ] Set up DNS records pointing to server
- [ ] Run full test suite: `bundle exec rspec`
- [ ] Review security: `bundle exec brakeman`
- [ ] Configure email delivery with Resend
- [ ] Set up monitoring/alerting
- [ ] Document your specific deployment configuration
- [ ] Test backup restoration procedure

## Internationalization (i18n) Guidelines

### Language Priority

Oroshi is a **Japanese-first application**. All user-facing text must:

1. **Use Japanese as the primary language** - All UI text, buttons, labels, messages should be in Japanese
2. **Use `t()` helper with locale files** - Never hardcode strings in views or controllers
3. **Avoid mixed languages** - Do not mix English and Japanese in the same context

### Required Practices

```ruby
# ✅ CORRECT - Use t() with locale key
<%= t('onboarding.buttons.skip') %>
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
  common:
    buttons:
      save: "保存"
      cancel: "キャンセル"
      back: "戻る"
      next: "次へ"
      skip: "スキップ"
      delete: "削除"
      edit: "編集"
    confirmations:
      are_you_sure: "よろしいですか？"
      delete_confirm: "本当に削除しますか？"
  onboarding:
    buttons:
      skip_for_now: "今はスキップ"
      resume_later: "後で再開"
    messages:
      skip_confirm: "オンボーディングをスキップしますか？後でダッシュボードから再開できます。"
```

### When Adding New UI Text

1. Add the Japanese translation to the appropriate locale file first
2. Use the `t()` helper in the view/controller
3. Never commit hardcoded strings in user-facing code
4. Run locale detection: `bin/rails locale:detect` (when available)

## Ralph - Autonomous Development Workflow

### Overview

Ralph is an autonomous AI development agent integrated into VS Code Copilot Chat. Ralph incrementally implements features from Product Requirements Documents (PRDs) stored in `scripts/ralph/prd.json`.

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
   - Run quality checks (rubocop + rspec)
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
- `AGENTS.md` - Oroshi-specific patterns and conventions
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

# 2. Tests (excluding slow system tests)
bundle exec rspec --exclude-pattern="spec/system/**/*_spec.rb"

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
scripts/ralph/progress.txt

# View remaining tasks
cat scripts/ralph/prd.json | jq '.userStories[] | select(.passes == false)'
```

**To create a new PRD:**

1. Copy `scripts/ralph/prd.json` to a new file
2. Update the `branchName`, `description`, and `userStories`
3. Create the git branch: `git checkout -b <branchName>`
4. Point Ralph at the new PRD

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

### Progress Log Format

Ralph appends to `progress.txt` after each story:

```
[YYYY-MM-DD HH:MM:SS] Story: <story title>
Implemented: <what was built>
Files: <list of modified files>
Tests: PASSING
Learnings:
- <reusable pattern discovered>
- <gotcha or constraint found>
```

### Legacy Bash Workflow (Optional)

The original Ralph workflow used a bash loop (`scripts/ralph/ralph.sh`):

```bash
# Run Ralph in loop mode (up to 10 iterations)
cd scripts/ralph
./ralph.sh 10
```

This repeatedly invokes `amp` (Anthropic's MCP client) with the prompt until:

- All stories have `passes: true`, OR
- Max iterations reached

**VS Code Copilot Integration** is now the preferred method as it provides:

- Better tool integration
- Persistent chat context
- IDE-native experience
- Real-time feedback

### Files Reference

- `.github/copilot-instructions.md` - Ralph's core instructions
- `AGENTS.md` - Oroshi patterns and conventions
- `scripts/ralph/prd.json` - Current task tracking
- `scripts/ralph/progress.txt` - Learning journal
- `scripts/ralph/prompt.md` - Legacy amp prompt (for reference)
- `scripts/ralph/ralph.sh` - Legacy bash loop (optional)

---

**Repository:** https://github.com/cmbaldwin/oroshi
**Last Updated:** January 8, 2026
**Rails Version:** 8.1.1
**Ruby Version:** 4.0.0

For development setup and general information, see [README.md](README.md).
For Ralph autonomous development, see the Ralph section above or `.github/copilot-instructions.md`.
