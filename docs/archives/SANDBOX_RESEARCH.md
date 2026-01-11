# Rails Engine Sandbox Patterns - Research Findings

**Date:** January 11, 2026
**Purpose:** Document best practices for Rails engine sandbox/demo applications based on research of major gems

## Executive Summary

This document summarizes research into how major Rails engine gems (Solidus, Spree, Devise, Active Admin, Refinery CMS) structure their sandbox/test applications. The findings guided Oroshi's decision to use a **generated sandbox** approach following the Solidus pattern.

---

## Key Finding: Generated vs Committed Sandboxes

### Generated Sandbox (Recommended for Complex Engines)

**Pattern:** Sandbox is created on-demand via script, not committed to repository

**Examples:** Solidus, Spree (partial), Active Admin

**Advantages:**
- Clean repository (no generated files in git)
- Always up-to-date with latest engine code
- Flexible (can be regenerated with different options)
- Supports multiple database adapters via environment variables

**Implementation:**
```bash
#!/usr/bin/env bash
# bin/sandbox

rm -rf ./sandbox
rails new sandbox --database=postgresql --skip-git
cd sandbox

# Add engine to Gemfile
cat >> Gemfile <<RUBY
gem 'my_engine', path: '..'
RUBY

bundle install
bin/rails db:create db:migrate
bin/rails generate my_engine:install
```

### Committed Sandbox (Simple Engines)

**Pattern:** Minimal test/dummy app committed to repository

**Examples:** Devise (`test/rails_app`), default Rails engine pattern (`test/dummy`)

**Advantages:**
- Simple, no generation script needed
- Stable test environment
- Good for CI/CD (no generation step)

**What to Commit:**
- Config files, routes, initializers
- Basic application structure

**What to .gitignore:**
```gitignore
/test/dummy/db/*.sqlite3
/test/dummy/log/*.log
/test/dummy/tmp/
/test/dummy/storage/
```

---

## Dependency Management Patterns

### Critical Rule: Runtime vs Development Dependencies

**Gemspec (`.gemspec`):**
```ruby
Gem::Specification.new do |spec|
  # ONLY runtime dependencies (what gem consumers need)
  spec.add_dependency 'rails', '>= 7.0'
  spec.add_dependency 'devise'
  spec.add_dependency 'ransack', '~> 4.0'

  # NEVER use add_development_dependency (deprecated in Bundler 2.1+)
end
```

**Gemfile:**
```ruby
source 'https://rubygems.org'

gemspec  # Loads runtime dependencies from .gemspec

# Development and test dependencies
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'capybara'
  gem 'selenium-webdriver'
end

group :development do
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'brakeman'
  gem 'solargraph'  # LSP for IDE
end

group :test do
  gem 'simplecov'
  gem 'database_cleaner'
end
```

### Examples from Major Gems

**Solidus Core (`core/solidus_core.gemspec`):**
- 40+ runtime dependencies
- NO development dependencies in gemspec
- All dev/test deps in root Gemfile

**Active Admin (`activeadmin.gemspec`):**
```ruby
spec.add_dependency 'arbre', '~> 2.0'
spec.add_dependency 'formtastic', '>= 5.0'
spec.add_dependency 'kaminari', '>= 1.2.1'
spec.add_dependency 'ransack', '>= 4.0'
# ... only runtime dependencies
```

**Spree Commerce:**
Uses monorepo with `common_spree_dependencies.rb` shared across all engines:
```ruby
# common_spree_dependencies.rb
group :test, :development do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  # ... 30+ dev/test gems
end
```

---

## CSS/JavaScript Bundling in Engines

### Challenge

Parent applications may not have:
- Node.js installed
- Tailwind CSS configured
- Asset pipeline set up

### Solution Patterns

#### Pattern 1: Precompile on Publish (Production-Ready Engines)

```ruby
# engine.rb
module MyEngine
  class Engine < ::Rails::Engine
    isolate_namespace MyEngine

    # Serve precompiled assets as static files
    config.app_middleware.use(
      Rack::Static,
      urls: ["/my-engine-assets"],
      root: MyEngine::Engine.root.join("public")
    )
  end
end
```

**Process:**
1. Build assets before gem release: `bin/rails assets:precompile`
2. Include `public/` directory in gemspec files
3. Serve via Rack::Static middleware
4. No parent app configuration required

**Examples:** Avo, production-focused admin engines

#### Pattern 2: Tailwind + Importmap Integration (Modern Approach)

```ruby
# engine.rb
module MyEngine
  class Engine < ::Rails::Engine
    isolate_namespace MyEngine

    # Compose importmap from engine
    initializer "my-engine.importmap", before: "importmap" do |app|
      app.config.importmap.paths << Engine.root.join("config/importmap.rb")
    end

    # Generate Tailwind config dynamically
    initializer "my-engine.tailwind" do
      ActiveSupport.on_load(:action_view) do
        # Scan engine views for Tailwind classes
      end
    end
  end
end
```

**Process:**
1. Engine provides `config/importmap.rb` with JavaScript deps
2. Tailwind config scans engine paths for utility classes
3. Parent app runs `rails tailwindcss:install` once

**Examples:** Active Admin, modern Rails engines

#### Pattern 3: Document Requirements (Pragmatic)

```markdown
## Installation

Your parent application must have:

1. Tailwind CSS: `bin/rails tailwindcss:install`
2. Importmap: `bin/rails importmap:install`

Then add to Gemfile:

```ruby
gem 'my_engine'
```

**Examples:** Many community gems, acceptable for internal use

---

## Procfile.dev Patterns

### Why Procfile.dev Matters

Modern Rails apps need multiple processes running:
- Web server (Puma)
- CSS compilation (Tailwind watch)
- JavaScript bundling (optional)
- Background jobs (Solid Queue, Sidekiq)

**Critical:** Always use `bin/dev`, NEVER just `rails server` in development.

### Monorepo Pattern (Solidus, Spree)

**Root `Procfile.dev`:**
```ruby
sandbox: foreman start -d sandbox -f sandbox/Procfile.dev
admin: bundle exec rake -C admin tailwindcss:watch
api: bundle exec rake -C api some:task
```

**Nested `sandbox/Procfile.dev`:**
```ruby
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
js: bin/rails importmap:watch
jobs: bundle exec rake solid_queue:start
```

**Benefits:**
- Delegates to sandbox's own Procfile
- Supports multiple sub-engines
- Clear separation of concerns

### Single Engine Pattern

**Generated `sandbox/Procfile.dev`:**
```ruby
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
```

**Created during sandbox generation:**
```bash
# In bin/sandbox script
cat > Procfile.dev <<PROCFILE
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
PROCFILE
```

---

## Multi-Database Configuration

For engines using Solid Queue, Solid Cache, and Solid Cable, a 4-database setup is required.

### Database YAML Structure

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  primary:
    <<: *default
    database: my_app_development
  queue:
    <<: *default
    database: my_app_development_queue
    migrations_paths: db/queue_migrate
  cache:
    <<: *default
    database: my_app_development_cache
    migrations_paths: db/cache_migrate
  cable:
    <<: *default
    database: my_app_development_cable
    migrations_paths: db/cable_migrate
```

### Schema Loading Pattern

**Critical:** Solid schemas must be loaded separately from main migrations.

```bash
# In bin/sandbox script
bin/rails db:create db:migrate
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable
```

**Engine provides schemas:**
- `db/queue_schema.rb` (Solid Queue tables)
- `db/cache_schema.rb` (Solid Cache tables)
- `db/cable_schema.rb` (Solid Cable tables)

---

## Sandbox Generation Script Patterns

### Solidus Pattern (Comprehensive)

```bash
#!/usr/bin/env bash
set -e

# Database selection via ENV
case "$DB" in
  postgres|postgresql)
    RAILSDB="postgresql"
    ;;
  mysql)
    RAILSDB="mysql"
    ;;
  *)
    RAILSDB="sqlite3"
    ;;
esac

# Clean slate
rm -rf ./sandbox

# Generate Rails app
rails new sandbox \
  --database="$RAILSDB" \
  --skip-git \
  --skip-test \
  --skip-bootsnap \
  --css=tailwind \
  --javascript=importmap

cd sandbox

# Add engine to Gemfile
cat >> Gemfile <<RUBY
gem 'solidus', path: '..'
gem 'solidus_admin', path: '../admin'

group :development, :test do
  gem 'debug'
  gem 'better_errors'
  gem 'binding_of_caller'
end
RUBY

bundle install

# Run installer
bin/rails generate solidus:install --auto-accept

echo "✅ Sandbox created!"
```

### Command Support Pattern

```bash
#!/usr/bin/env bash
set -e

COMMAND="${1:-create}"

show_help() {
  cat <<EOF
Usage: bin/sandbox [command]

Commands:
  create    Create sandbox (default)
  destroy   Remove sandbox
  reset     Destroy and recreate
  help      Show this help
EOF
}

case "$COMMAND" in
  help)
    show_help
    exit 0
    ;;
  destroy)
    rm -rf ./sandbox
    echo "✅ Sandbox removed"
    exit 0
    ;;
  reset)
    rm -rf ./sandbox
    # Continue to create
    ;;
esac

# Create sandbox...
```

---

## Modern Alternative: Combustion

For engines focused on testing (not demos), Combustion provides minimal infrastructure.

### What is Combustion?

"Simple, elegant testing for Rails Engines without a full dummy app"

### Structure

```
spec/
  internal/
    config/
      database.yml
      routes.rb
    db/
      schema.rb
    app/
      models/
      controllers/
```

### Setup

```ruby
# spec/spec_helper.rb
require 'bundler/setup'
require 'combustion'

Combustion.initialize! :active_record, :action_controller

require 'rspec/rails'
```

### Advantages

- Minimal files (only what you need)
- No migrations (just schema.rb)
- Selective component loading
- Easier maintenance than full dummy app

### When to Use

- Testing-focused engines
- No need for full demo application
- Prefer simplicity over completeness

---

## Real-World Examples

### Solidus

**Sandbox Location:** `/sandbox` (generated, gitignored)

**Generation:** `bin/sandbox` script

**Features:**
- Supports PostgreSQL, MySQL, SQLite via `$DB` env var
- Includes authentication (solidus_auth_devise)
- Pre-loads sample data
- Configures Tailwind CSS
- Creates Procfile.dev

**Gemfile Pattern:**
```ruby
source 'https://rubygems.org'
gemspec  # Loads solidus.gemspec

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  # ... 30+ dev/test gems
end
```

### Spree Commerce

**Sandbox Location:** `/sample` (committed gem)

**Structure:** Monorepo with multiple engines:
- `core/` - Spree::Core
- `api/` - Spree::API
- `admin/` - Spree::Admin
- `storefront/` - Spree::Storefront
- `sample/` - Sample data gem

**Dependency Management:**
```ruby
# Each engine's Gemfile
eval_gemfile('../common_spree_dependencies.rb')
gem 'spree_core', path: '../core'
gemspec
```

**Shared Dependencies:** `common_spree_dependencies.rb` centralizes all dev/test gems

### Active Admin

**Test App:** Generated dynamically (not committed)

**Generation:** Rails template file (`spec/support/rails_template.rb`)

**Template Features:**
```ruby
# Install CSS bundling with Tailwind
run "bundle add tailwindcss-rails"
rails_command "tailwindcss:install"

# Configure importmap
run "bundle add importmap-rails"
rails_command "importmap:install"

# Generate Active Admin installation
generate "active_admin:install"

# Configure Tailwind for Active Admin
inject_into_file "config/tailwind.config.js" do
  # Add Active Admin paths
end
```

### Devise

**Test App Location:** `/test/rails_app` (committed)

**Pattern:** Full Rails app inside test directory

**Gemfile:** Uses parent gem's dependencies (no separate Gemfile)

**Multi-Version Testing:**
```
/gemfiles
  rails_6.1.gemfile
  rails_7.0.gemfile
  rails_7.1.gemfile
```

**Usage:**
```bash
BUNDLE_GEMFILE=gemfiles/rails_7.1.gemfile bundle exec rspec
```

---

## Recommendations Summary

### ✅ Use Generated Sandbox If:
- Complex engine with full-featured demo needed
- Want to support multiple database adapters
- Need fresh sandbox for different scenarios
- Following Solidus/Spree patterns

### ✅ Use Committed Test App If:
- Simple engine with basic testing needs
- Stable test environment preferred
- No need for complex demos

### ✅ Use Combustion If:
- Testing-focused (no demo needed)
- Prefer minimal infrastructure
- Modern approach to engine testing

---

## Best Practices Checklist

### Repository Structure
- [ ] Sandbox is gitignored if generated
- [ ] `bin/sandbox` script provides create/destroy/reset commands
- [ ] Clear documentation in README

### Dependencies
- [ ] Runtime dependencies in `.gemspec` only
- [ ] Development/test dependencies in `Gemfile`
- [ ] Use `gemspec` directive in Gemfile
- [ ] Never use `add_development_dependency`

### Asset Pipeline
- [ ] Either precompile before release OR
- [ ] Document parent app requirements OR
- [ ] Provide dynamic Tailwind/Importmap integration

### Development Experience
- [ ] Provide `Procfile.dev` for multi-process development
- [ ] Document "use `bin/dev`, not `rails server`"
- [ ] Include CSS compilation in Procfile

### Multi-Database (if applicable)
- [ ] Provide complete `database.yml` template
- [ ] Include schema files for Solid gems
- [ ] Script automatic schema loading

### Documentation
- [ ] Quick start (1-3 commands max)
- [ ] Sandbox generation instructions
- [ ] Demo user credentials
- [ ] Troubleshooting common issues

---

## References

### Primary Research Sources

- [Solidus GitHub Repository](https://github.com/solidusio/solidus)
  - `bin/sandbox` script
  - Multi-database configuration
  - Procfile.dev patterns

- [Spree Commerce GitHub Repository](https://github.com/spree/spree)
  - Monorepo structure
  - `common_spree_dependencies.rb` pattern
  - Sample gem approach

- [Active Admin GitHub Repository](https://github.com/activeadmin/activeadmin)
  - Rails template for sandbox generation
  - Tailwind + Importmap integration
  - Dynamic configuration

- [Devise GitHub Repository](https://github.com/heartcombo/devise)
  - Committed test app pattern
  - Multi-version testing with gemfiles

- [Combustion GitHub Repository](https://github.com/pat/combustion)
  - Minimal test infrastructure
  - Modern alternative to dummy apps

### Rails Guides

- [Getting Started with Engines](https://guides.rubyonrails.org/engines.html)
- [Testing Rails Engines: The Dummy App](https://medium.com/@sarahbranon/testing-rails-engines-the-dummy-app-d20d25c20466)

### Asset Bundling References

- [Working with Rails Engines, Importmap and TailwindCSS](https://mariochavez.io/desarrollo/2023/08/23/working-with-rails-engines-importmap-tailwindcss/)
- [How to Bundle Assets in a Rails Engine](https://avohq.io/blog/how-to-bundle-assets-in-a-rails-engine)
- [Rails Engine and Tailwind CSS v4: A Complete Guide](https://medium.com/@roonglit/rails-engine-and-tailwind-css-v4-a-complete-guide-9186bcffe1fa)

---

## Conclusion

Based on research of major Rails engine gems, the **generated sandbox** approach (Solidus pattern) is the recommended best practice for complex engines with full-featured demos. This provides:

- Clean repository (no generated files)
- Flexibility (multiple database adapters, regeneration)
- Production-like environment (Tailwind, Importmap, Procfile.dev)
- Clear separation between engine code and demo app

For Oroshi specifically, this approach enables:
- Multi-database setup demonstration (Solid Queue, Cache, Cable)
- Complete onboarding workflow testing
- Japanese-first UI with proper asset compilation
- Easy regeneration for different scenarios

**Oroshi Implementation:** See `bin/sandbox` script and updated README.md

---

**Last Updated:** January 11, 2026
**Oroshi Version:** 1.0.0
**Research Scope:** Solidus, Spree, Devise, Active Admin, Refinery CMS, Combustion
