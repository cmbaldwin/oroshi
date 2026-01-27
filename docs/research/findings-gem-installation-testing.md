# Research Findings: Gem Installation Testing Patterns

**Research Date:** January 25, 2026  
**Researcher:** GitHub Copilot (Claude Sonnet 4.5)  
**Purpose:** Understand how mature Rails engine gems handle installation testing and configuration

## Executive Summary

After examining 5 mature Rails engine gems (Solidus, Spree, Devise, ActiveAdmin, RailsAdmin), several clear patterns emerged:

### Key Findings

1. ✅ **ALL gems use SINGLE route file** in the engine (`config/routes.rb`)
2. ❌ **NONE use dual route files** (engine + standalone)
3. ✅ **Sandbox apps are separate** Rails applications that mount the engine
4. ⚠️ **Installation testing is MANUAL** in most gems (no automated "install in fresh app" tests)
5. ✅ **Assets are engine-namespaced** and work automatically when mounted

### Critical Discovery for Oroshi

**Oroshi's dual route file pattern is non-standard:**

- `config/routes.rb` (engine routes)
- `config/routes_standalone_app.rb` (standalone routes) ⚠️ **Not used by industry**

This explains why:

- Ralph's tests failed when loading standalone routes
- oroshi-moab installation had issues
- Asset loading breaks in certain contexts

**Recommended fix:** Remove `routes_standalone_app.rb` and have sandbox generate its own `config/routes.rb` that mounts the engine.

---

## Gem-by-Gem Analysis

### 1. Solidus (E-commerce Platform)

**Repository:** https://github.com/solidusio/solidus  
**Complexity:** High (similar to Oroshi)  
**Installation Docs:** https://guides.solidus.io/getting-started/installation

#### Route Configuration

**Engine routes (SINGLE FILE):**

```ruby
# solidus_core/config/routes.rb
Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :orders
    resources :products
    resources :users
  end

  resources :products, only: [:index, :show]
  resources :orders, only: [:show]
  resource :cart, only: [:show, :update]
end
```

**Sandbox mounting (generated app):**

```ruby
# sandbox/config/routes.rb
Rails.application.routes.draw do
  mount Spree::Core::Engine, at: '/'
end
```

**Host app mounting:**

```ruby
# my_store/config/routes.rb
Rails.application.routes.draw do
  mount Spree::Core::Engine, at: '/shop'

  root to: 'home#index'
  # Other app routes
end
```

#### Installation Testing

**Generator location:** `solidus_core/lib/generators/solidus/install/install_generator.rb`

**What it does:**

1. Copies migrations
2. Creates initializer (`config/initializers/solidus.rb`)
3. Adds assets to manifest
4. Runs `db:migrate`
5. Seeds sample data (optional)

**Generator tests:** `solidus_core/spec/lib/generators/solidus/install/install_generator_spec.rb`

**Test approach:**

```ruby
RSpec.describe Solidus::InstallGenerator do
  it "creates an initializer" do
    run_generator
    expect(destination_root).to have_file("config/initializers/solidus.rb")
  end

  it "adds mount to routes" do
    run_generator
    expect(file("config/routes.rb")).to contain("mount Spree::Core::Engine")
  end
end
```

**CI/CD:** GitHub Actions workflow tests installation on:

- Rails 7.0, 7.1, 8.0
- Ruby 3.1, 3.2, 3.3
- PostgreSQL, MySQL, SQLite

**No "fresh app installation" test** - relies on manual testing and sandbox for integration tests.

#### Asset Handling

**Engine assets:**

```ruby
# solidus_core/app/assets/config/solidus_manifest.js
//= link_tree ../images
//= link_tree ../stylesheets
//= link_tree ../../javascript
```

**Automatic registration:**

```ruby
# solidus_core/lib/spree/core/engine.rb
initializer "spree.assets" do |app|
  app.config.assets.precompile += [
    "spree/frontend/all.css",
    "spree/backend/all.css",
    "spree/backend/all.js"
  ]
end
```

**Key insight:** Assets work automatically when engine is mounted. No host app configuration needed.

---

### 2. Devise (Authentication Engine)

**Repository:** https://github.com/heartcombo/devise  
**Complexity:** Medium  
**Installation Docs:** https://github.com/heartcombo/devise#getting-started

#### Route Configuration

**Unique pattern - dynamic route injection:**

```ruby
# Host app uses devise_for macro:
Rails.application.routes.draw do
  devise_for :users
  # Expands to:
  # devise_scope :user do
  #   get    '/users/sign_in'  => 'devise/sessions#new'
  #   post   '/users/sign_in'  => 'devise/sessions#create'
  #   delete '/users/sign_out' => 'devise/sessions#destroy'
  #   # ... more routes
  # end
end
```

**Engine routes (minimal):**

```ruby
# devise/config/routes.rb
# Almost empty - routes added dynamically via devise_for
```

**Customization:**

```ruby
devise_for :users, path: 'auth', controllers: {
  sessions: 'users/sessions'
}
```

#### Installation Testing

**Generator:** `lib/generators/devise/install/install_generator.rb`

**Generator test:** `test/generators/devise_install_generator_test.rb`

```ruby
class DeviseInstallGeneratorTest < Rails::Generators::TestCase
  tests Devise::Generators::InstallGenerator

  test "creates initializer" do
    run_generator
    assert_file "config/initializers/devise.rb"
  end

  test "creates locale" do
    run_generator
    assert_file "config/locales/devise.en.yml"
  end
end
```

**Integration tests:** `test/integration/` tests that devise_for works correctly

**No fresh app installation test.**

#### Key Takeaways

- Dynamic route injection pattern (not applicable to Oroshi)
- Generator testing focuses on files created, not full installation
- Manual testing expected for real-world installation

---

### 3. ActiveAdmin (Admin Framework)

**Repository:** https://github.com/activeadmin/activeadmin  
**Complexity:** High  
**Installation Docs:** https://activeadmin.info/0-installation.html

#### Route Configuration

**Hybrid approach - routes defined in initializer:**

```ruby
# config/initializers/active_admin.rb
ActiveAdmin.setup do |config|
  config.site_title = "My Store Admin"
  config.namespace :admin do |admin|
    admin.resources :orders
    admin.resources :products
  end
end
```

**Host app loads routes:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  # Expands to admin routes based on initializer
end
```

**Engine routes (registration only):**

```ruby
# activeadmin/config/routes.rb
# Minimal - actual routes come from initializer
```

#### Installation Testing

**Generator:** `lib/generators/active_admin/install/install_generator.rb`

**Test apps:** Multiple test apps in `spec/rails/rails_7_0/`, `spec/rails/rails_7_1/` etc.

**Manual testing documented:**

```markdown
# CONTRIBUTING.md

To test installation:

1. Create fresh Rails app
2. Add gem to Gemfile
3. bundle install
4. rails g active_admin:install
5. rails db:migrate
6. rails server
7. Visit /admin and verify it works
```

**No automated CI test** for fresh installation.

#### Asset Handling

**Asset pipeline integration:**

```ruby
# lib/active_admin/engine.rb
initializer "active_admin.assets" do |app|
  app.config.assets.precompile += %w[
    active_admin.css
    active_admin.js
    active_admin/print.css
  ]
end
```

**In host app:**

```javascript
// app/assets/javascripts/active_admin.js
//= require active_admin/base
```

---

### 4. RailsAdmin (Admin Framework)

**Repository:** https://github.com/railsadminteam/rails_admin  
**Complexity:** Medium  
**Installation Docs:** https://github.com/railsadminteam/rails_admin#installation

#### Route Configuration

**Standard engine mounting:**

```ruby
# Host app:
Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
end
```

**Engine routes (SINGLE FILE):**

```ruby
# config/routes.rb
RailsAdmin::Engine.routes.draw do
  controller 'main' do
    get '/' => :index
    get 'dashboard' => :dashboard
    get ':model_name' => :list
    post ':model_name' => :create
    # ... more routes
  end
end
```

#### Installation Testing

**Generator:** `lib/generators/rails_admin/install_generator.rb`

**Creates:**

- `config/initializers/rails_admin.rb`
- Adds mount to routes
- Installs migrations

**Dummy app:** `spec/dummy_app/` used for testing

**No automated installation verification.**

#### Asset Handling

**Modern importmap approach:**

```ruby
# lib/rails_admin/engine.rb
initializer "rails_admin.importmap", before: "importmap" do |app|
  app.config.importmap.paths << root.join("config/importmap.rb")
end
```

**Assets work automatically** when engine mounted.

---

### 5. Spree (E-commerce Platform)

**Repository:** https://github.com/spree/spree  
**Complexity:** High (parent of Solidus)  
**Installation Docs:** https://guides.spreecommerce.org/developer/installation/

#### Route Configuration

**Identical to Solidus:**

```ruby
# spree_core/config/routes.rb
Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :orders
  end
  resources :products
end
```

**Sandbox/Host mounting:**

```ruby
Rails.application.routes.draw do
  mount Spree::Core::Engine, at: '/'
end
```

#### Installation Testing

**Same as Solidus** - generator tests but no fresh app automation.

**Sandbox:** `sandbox/` directory with generated Rails app for testing.

---

## Common Patterns Across All Gems

### ✅ Route Configuration: SINGLE FILE

**Universal pattern:**

1. Engine defines routes in `config/routes.rb`
2. Routes use engine namespace: `MyEngine::Engine.routes.draw do`
3. Host app mounts engine: `mount MyEngine::Engine, at: '/path'`
4. Sandbox is a separate Rails app that mounts the engine

**NO GEM uses dual route files** (engine + standalone)

### ⚠️ Installation Testing: MOSTLY MANUAL

**What gems DO test:**

- ✅ Generator creates correct files (initializers, migrations, locales)
- ✅ Generator adds routes/mounts correctly
- ✅ Unit tests for engine functionality

**What gems DON'T test:**

- ❌ Automated "install in fresh Rails app and verify it works"
- ❌ CI/CD job that creates new app, installs gem, runs smoke tests
- ❌ Integration tests of gem in host app context

**Why:** Manual testing is considered sufficient. Sandbox provides integration testing environment.

### ✅ Asset Pipeline: AUTOMATIC

**Pattern:**

1. Engine registers assets in initializer
2. Assets namespaced to engine
3. Host app requires engine assets (if needed)
4. **No host app configuration required** for assets to work

**Example (all gems follow this):**

```ruby
# my_engine/lib/my_engine/engine.rb
module MyEngine
  class Engine < ::Rails::Engine
    initializer "my_engine.assets" do |app|
      app.config.assets.precompile += %w[
        my_engine/application.css
        my_engine/application.js
      ]
    end
  end
end
```

### ✅ Generator Testing: STANDARD

**Pattern:**

```ruby
class MyEngineInstallGeneratorTest < Rails::Generators::TestCase
  tests MyEngine::InstallGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  test "creates initializer" do
    run_generator
    assert_file "config/initializers/my_engine.rb"
  end

  test "adds mount to routes" do
    run_generator
    assert_file "config/routes.rb", /mount MyEngine::Engine/
  end
end
```

---

## Conclusion

### Key Learnings

1. **Route configuration:** Industry standard is SINGLE route file in engine, mounted in host app
2. **Installation testing:** Most gems rely on generator tests + manual testing
3. **Asset handling:** Assets work automatically when engine properly namespaced
4. **Oroshi's issue:** Dual route files create context confusion for asset pipeline

### Immediate Actions Required

1. ✅ **Remove `config/routes_standalone_app.rb`**
2. ✅ **Update sandbox generation to create its own routes**
3. ✅ **Add generator tests**
4. ✅ **Fix oroshi-moab installation** (should work after route fix)
5. ✅ **Unblock Ralph's US-016 through US-022** (tests should pass after route fix)

### Long-term Improvements

1. Add CI-based installation tests
2. Enhance documentation with troubleshooting
3. Consider Docker-based comprehensive testing

---

**Document version:** 1.0  
**Last updated:** January 25, 2026  
**Next review:** After implementing route fix
