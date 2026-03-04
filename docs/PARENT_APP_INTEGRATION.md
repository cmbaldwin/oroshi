# Oroshi Parent Application Integration Guide

**Document Date:** January 29, 2026
**Based On:** Sandbox improvements and oroshi-moab implementation
**Rails:** 8.1.2 | **Ruby:** 4.0.0

## Overview

This document captures lessons learned from integrating the Oroshi gem into parent applications (sandbox and oroshi-moab) after the route refactoring and configuration improvements.

## What Worked ✅

### 1. Minimal Devise Configuration

**Location:** `config/initializers/devise.rb`

**What worked:**
- Wrapping the entire Devise configuration in `if defined?(Devise)` prevents initialization errors during database creation
- Minimal configuration (~24 lines) vs verbose default (~300+ lines)
- Environment-aware configuration using ENV variables with sensible defaults
- Using `authentication_keys: [:login]` to allow username OR email login

**Recommended configuration:**
```ruby
if defined?(Devise)
  Devise.setup do |config|
    config.secret_key = Rails.application.credentials.secret_key_base || ENV.fetch('DEVISE_KEY', 'your_app_dev_key')
    config.mailer_sender = ENV.fetch('MAIL_SENDER', 'noreply@yourdomain.com')
    config.mailer = 'Devise::Mailer'
    config.parent_mailer = 'ActionMailer::Base'
    require 'devise/orm/active_record'
    config.authentication_keys = [:login]
    config.case_insensitive_keys = [:email]
    config.strip_whitespace_keys = [:email]
    config.skip_session_storage = [:http_auth]
    config.stretches = Rails.env.test? ? 1 : 11
    config.send_email_changed_notification = false
    config.send_password_change_notification = false
    config.confirm_within = 3.days
    config.reconfirmable = false
    config.confirmation_keys = [:email]
    config.expire_all_remember_me_on_sign_out = true
    config.password_length = 6..128
    config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
    config.scoped_views = true
    config.sign_out_via = :delete
  end
end
```

### 2. Clean User Model

**Location:** `app/models/user.rb`

**What worked:**
- Simple, focused model without unnecessary complexity
- Proper Devise module loading
- Username OR email authentication via `attr_accessor :login` and custom `find_for_database_authentication`
- Integration with Oroshi via `has_one :onboarding_progress`

**Recommended User model:**
```ruby
class User < ApplicationRecord
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates_format_of :username, with: /\A[a-zA-Z0-9_.]*\z/

  enum :role, { user: 0, managerial: 1, admin: 2, supplier: 3, employee: 4 }

  has_one :onboarding_progress, class_name: "Oroshi::OnboardingProgress", dependent: :destroy

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         authentication_keys: [:login]

  attr_accessor :login

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { value: login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end
end
```

### 3. Routes Configuration

**Location:** `config/routes.rb`

**What worked:**
- Mounting engine at root path (`/`) works perfectly
- Devise routes outside the engine namespace
- Health check and PWA routes coexist without conflicts

**Recommended routes:**
```ruby
Rails.application.routes.draw do
  # Devise for user authentication
  devise_for :users

  # Mount Oroshi engine at root
  mount Oroshi::Engine, at: "/"

  # Health check and PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
```

### 4. Database Configuration

**Location:** `config/database.yml`

**What worked:**
- 4-database setup (primary, queue, cache, cable)
- Proper migrations_paths for each database
- Environment-aware production configuration

**Recommended database.yml:**
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  primary:
    <<: *default
    database: your_app_development
  cache:
    <<: *default
    database: your_app_development_cache
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: your_app_development_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: your_app_development_cable
    migrations_paths: db/cable_migrate

test:
  primary:
    <<: *default
    database: your_app_test
  cache:
    <<: *default
    database: your_app_test_cache
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: your_app_test_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: your_app_test_cable
    migrations_paths: db/cable_migrate

production:
  primary: &primary_production
    <<: *default
    database: <%= ENV["POSTGRES_DB"] || "your_app_production" %>
    username: <%= ENV["POSTGRES_USER"] || "your_app" %>
    password: <%= ENV["POSTGRES_PASSWORD"] %>
    host: <%= ENV["DB_HOST"] %>
    port: <%= ENV["DB_PORT"] || 5432 %>
  cache:
    <<: *primary_production
    database: your_app_production_cache
    migrations_paths: db/cache_migrate
  queue:
    <<: *primary_production
    database: your_app_production_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *primary_production
    database: your_app_production_cable
    migrations_paths: db/cable_migrate
```

### 5. Procfile.dev Configuration

**Location:** `Procfile.dev`

**What worked:**
- Simple 2-process setup: web + jobs
- Jobs worker for Solid Queue background processing
- Port 3000 for local development

**Recommended Procfile.dev:**
```
web: bin/rails server -p 3000
jobs: bin/jobs
```

### 6. Gemfile Configuration

**Location:** `Gemfile`

**What worked:**
- Using path gem for local development: `gem "oroshi", path: "../oroshi"`
- Including all Solid gems (solid_queue, solid_cache, solid_cable)
- Keeping Devise in parent app (not relying on engine's Devise)

**Key gems needed:**
```ruby
gem "rails", "~> 8.1.2"
gem "oroshi", path: "../oroshi"  # Or version from RubyGems
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "devise"
```

### 7. Setup Process

**What worked:**
1. Create Rails app: `rails new your_app --database=postgresql`
2. Add Oroshi gem to Gemfile
3. Run `bundle install`
4. Copy database.yml configuration (4 databases)
5. Add Devise initializer with conditional wrapper
6. Create User model with Oroshi integration
7. Update routes.rb to mount engine
8. Run `bin/rails db:create`
9. Run `bin/rails db:migrate` (copies migrations from engine automatically)
10. **CRITICAL:** Run `bin/rails db:schema:load:queue db:schema:load:cache db:schema:load:cable` (must be done BEFORE starting jobs worker)
11. Run `bin/rails db:seed` (if you have seeds)
12. Start server: `bin/dev` or `bin/rails server`

**Important Notes:**
- Step 10 is CRITICAL - the Solid Queue worker will crash without these schemas loaded
- The schemas must be loaded separately because they use different databases
- If you skip step 10, the jobs worker will fail with "relation 'solid_queue_processes' does not exist"

### 8. Server Startup

**What worked:**
- Server boots cleanly with no errors
- All routes accessible
- Devise authentication working
- Oroshi engine routes accessible
- Background jobs processing (when bin/jobs is running)

## What Didn't Work (Fixed) ❌ → ✅

### 1. Verbose Devise Configuration

**Problem:** Default Devise initializer is 300+ lines and overwhelming
**Solution:** Minimal 24-line configuration wrapped in `if defined?(Devise)`
**Impact:** Cleaner codebase, easier to understand, prevents initialization errors

### 2. Missing Jobs Worker in Procfile

**Problem:** Procfile.dev didn't include Solid Queue worker
**Solution:** Added `jobs: bin/jobs` to Procfile.dev
**Impact:** Background jobs now process automatically when running `bin/dev`

### 3. Complex User Model

**Problem:** Overly complex User model with unnecessary methods
**Solution:** Simplified to essential methods only
**Impact:** Easier to maintain and understand

## Critical Patterns for Parent Apps

### 1. Conditional Gem Initializers

**Always wrap gem-specific initializers in conditional checks:**
```ruby
if defined?(GemName)
  # configuration here
end
```

This prevents errors during:
- `bin/rails db:create`
- `bin/rails db:migrate`
- Database schema loading

### 2. Engine Mounting at Root

**Oroshi works best mounted at root path:**
```ruby
mount Oroshi::Engine, at: "/"
```

This avoids path prefix issues and makes the engine feel like a native part of the app.

### 3. Devise Outside Engine

**Parent app must provide Devise routes:**
```ruby
devise_for :users
```

This is outside the engine namespace and handled by the parent application.

### 4. Route Helper Usage

**In engine views, use `main_app` prefix for parent routes:**
```erb
<%= link_to "Login", main_app.new_user_session_path %>
<%= link_to "Home", main_app.root_path %>
```

**In parent views, use `oroshi` prefix for engine routes:**
```erb
<%= link_to "Orders", oroshi.orders_path %>
```

### 5. Schema Loading vs Migrations

**For Solid gems, use schema loading:**
```bash
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable
```

Don't run migrations for these databases as they don't have migration files in the parent app.

## Testing the Integration

### Quick Integration Test

```bash
# 1. Check database connections
bin/rails runner "puts ActiveRecord::Base.connection.current_database"
bin/rails runner "puts SolidQueue::Job.connection.current_database"
bin/rails runner "puts SolidCache::Entry.connection.current_database"

# 2. Check migrations
bin/rails db:migrate:status | head -10

# 3. Check User model
bin/rails runner "puts User.count"

# 4. Check engine routes
bin/rails routes | grep oroshi | head -10

# 5. Start server
bin/rails server

# 6. Visit http://localhost:3000
# Should redirect to login page
```

### Full Integration Test

```bash
# 1. Create test user
bin/rails runner "
  user = User.create!(
    username: 'testuser',
    email: 'test@example.com',
    password: 'password123',
    password_confirmation: 'password123',
    role: :admin
  )
  user.skip_confirmation!
  user.save!
  puts 'Created user: ' + user.email
"

# 2. Check background jobs
bin/jobs &
bin/rails runner "
  SomeJob.perform_later
  sleep 2
  puts 'Jobs processed: ' + SolidQueue::Job.finished.count.to_s
"

# 3. Check routes work
curl -I http://localhost:3000/
curl -I http://localhost:3000/users/sign_in
```

## Common Issues and Solutions

### Issue: "No route matches [GET] /users/sign_in"
**Solution:** Ensure `devise_for :users` is in `config/routes.rb`

### Issue: "Solid Queue jobs not processing" / "ERROR: relation 'solid_queue_processes' does not exist"
**Problem:** The queue database exists but doesn't have the Solid Queue tables loaded.

**Solution:**
```bash
# Load all Solid schemas after creating databases
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable
```

**Important:** Always load Solid schemas separately from main migrations. They use separate databases and need their own schema loading.

### Issue: "Database oroshi_your_app_queue does not exist"
**Solution:** Run `bin/rails db:create` to create all 4 databases

### Issue: "Uninitialized constant Devise"
**Solution:** Wrap Devise initializer in `if defined?(Devise)`

### Issue: "undefined method 'devise' for User"
**Solution:** Ensure Devise gem is in Gemfile and run `bundle install`

### Issue: Jobs worker crashes immediately on startup
**Problem:** The jobs worker tries to connect to the queue database before tables are loaded.

**Solution:**
1. First ensure schemas are loaded: `bin/rails db:schema:load:queue db:schema:load:cache db:schema:load:cable`
2. Then start the jobs worker: `bin/jobs`
3. Or add to Procfile.dev: `jobs: bin/jobs`

### Issue: Parent app CSS overriding gem CSS
**Problem:** Parent application has its own `app/assets/stylesheets/` directory with custom CSS that overrides the Oroshi gem's styling.

**Solution:** Remove the parent app's stylesheets directory entirely to use only the gem's CSS:
```bash
rm -rf app/assets/stylesheets
```

**Why this works:**
- Rails engines serve assets from their own `app/assets` directory
- When a parent app has its own stylesheets with the same name (e.g., `application.css`), they take precedence
- Removing the parent app's stylesheets ensures only the gem's CSS is loaded
- The gem's layout automatically includes the correct stylesheets

**Result:** The application will use the Oroshi gem's teal/cyan color scheme and Bootstrap-based styling consistently across all pages.

### Issue: Onboarding checklist not appearing in navbar

**Problem:** After creating a new user or when the admin user logs in, the onboarding checklist doesn't appear in the navbar, even though the user hasn't completed onboarding.

**Cause:** The onboarding checklist dropdown (`app/views/oroshi/onboarding/_checklist_dropdown.html.erb`) checks for the existence of `current_user.onboarding_progress` before rendering. However, the `onboarding_progress` record is only created when a user first visits the onboarding controller. This creates a chicken-and-egg problem where new users can't see the onboarding checklist until they somehow navigate to the onboarding page.

**Solution:** Create the `onboarding_progress` record for users who need to complete onboarding:

```ruby
# For a specific user (e.g., in Rails console or seed file)
user = User.find_by(username: 'admin')
user.create_onboarding_progress!

# Or add to your seed file for all new users
User.all.each do |user|
  user.create_onboarding_progress! unless user.onboarding_progress
end
```

**Alternative solution (for parent app):** Create an initializer that automatically creates onboarding progress for new users:

```ruby
# config/initializers/oroshi_auto_onboarding.rb
Rails.application.config.to_prepare do
  # Only run if Oroshi engine is loaded
  if defined?(Oroshi)
    # Hook into user creation to automatically create onboarding progress
    User.after_create do |user|
      user.create_onboarding_progress! unless user.onboarding_progress
    end
  end
end
```

**Verification:**

```bash
# Check if user has onboarding progress
bin/rails runner "puts User.find_by(username: 'admin').onboarding_progress.inspect"

# Should output something like:
# #<Oroshi::OnboardingProgress id: 1, completed_at: nil, skipped_at: nil, checklist_dismissed_at: nil, ...>
```

Once the record exists, the onboarding checklist will appear in the navbar showing incomplete steps.

## Recommendations for README Updates

### 1. Add Quick Start Section

Should include:
- Prerequisites (Ruby, Rails, PostgreSQL versions)
- Step-by-step installation (10 steps listed above)
- First-time setup commands
- How to create an admin user

### 2. Add Parent App Integration Section

Should include:
- Database configuration (4 databases)
- Devise setup (minimal config)
- User model requirements
- Routes configuration
- Procfile.dev setup

### 3. Add Troubleshooting Section

Should include:
- Common errors and solutions
- Database connection issues
- Devise configuration issues
- Route conflicts
- Background job issues

### 4. Add Testing Integration Section

Should include:
- Quick test commands
- How to verify installation
- How to create test data
- How to check background jobs

### 5. Update Example Code

Should include:
- Complete Gemfile example
- Complete database.yml example
- Complete routes.rb example
- Complete User model example
- Complete Devise initializer example

## Next Steps

1. ✅ Update [README.md](../README.md) with parent app integration guide
2. ✅ Update sandbox script to include jobs worker in Procfile.dev
3. ✅ Create installation verification rake task (already exists: `oroshi:verify_installation`)
4. ✅ Document common gotchas and solutions
5. 📝 Create video tutorial or animated GIF showing installation

## Conclusion

The integration process is now streamlined and works flawlessly when following these patterns:
- Minimal, conditional gem configurations
- Clean User model with Oroshi integration
- Proper database setup (4 databases)
- Jobs worker in Procfile
- Engine mounted at root

The key insight is that **simplicity wins** - minimal configurations that are wrapped in conditional checks prevent the majority of issues that users encounter during installation.

---

**Last Updated:** January 29, 2026
**Status:** ✅ Verified working in both sandbox and oroshi-moab
**Next Review:** After next major version release
