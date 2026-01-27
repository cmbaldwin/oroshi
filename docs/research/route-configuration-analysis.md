# Route Configuration Architecture Analysis

**Research Date:** January 25, 2026  
**Researcher:** Ralph + Copilot  
**Context:** Blocked on US-016 through US-022 due to asset loading failures  
**Root Cause:** Non-standard dual route file pattern

---

## Current State: Dual Route Pattern

### File Structure

```
config/
├── routes.rb                      # Engine routes (partial)
├── routes_standalone_app.rb       # Standalone app routes
├── routes_oroshi_engine.rb        # Documentation only
└── routes.rb.engine               # Documentation only
```

### Current routes.rb

```ruby
Oroshi::Engine.routes.draw do
  root to: "dashboard#show"
  
  resource :dashboard, only: [:show]
  
  # Shallow nested resources for product management
  resources :stores, shallow: true do
    resources :products do
      member do
        post :duplicate
      end
    end
  end
  
  # ... more engine routes
end
```

### Current routes_standalone_app.rb

```ruby
Rails.application.routes.draw do
  devise_for :users
  
  mount Oroshi::Engine => "/", as: 'oroshi'
  
  # Health check endpoints
  get "up" => "rails/health#show", as: :rails_health_check
end
```

### Problems with This Pattern

1. **Asset Pipeline Confusion**
   - Test environment doesn't know which routes to load
   - Assets referenced via `oroshi.some_path` fail when standalone routes mount at "/"
   - Main app routing helpers (`main_app.some_path`) not available in engine views
   - Asset paths resolve incorrectly during test runs

2. **Non-Standard Architecture**
   - No mature Rails engine uses this pattern
   - Violates Rails engine conventions
   - Makes gemification impossible

3. **Installation Failures**
   - `oroshi-moab` tries to mount Oroshi but routes already defined at root
   - Namespace collisions between engine and application
   - Assets don't load in consuming applications

4. **Developer Confusion**
   - Two sources of truth for routing
   - Unclear which file to modify
   - Documentation burden

---

## Industry Standard: Single Route File Pattern

### Research Findings Summary

Analyzed 5 mature Rails engines:
- **Solidus** (Spree fork, e-commerce platform)
- **Spree** (e-commerce engine)
- **Devise** (authentication gem)
- **ActiveAdmin** (admin framework)
- **RailsAdmin** (admin interface)

**Finding:** ALL use single route file in engine. NONE use dual routes.

### Pattern: Devise

```ruby
# devise/config/routes.rb
Devise.routes.draw do
  # All Devise routes in engine namespace
  devise_scope :user do
    get "sign_in", to: "sessions#new"
    # ... more routes
  end
end
```

### Pattern: Solidus

```ruby
# solidus/config/routes.rb
Spree::Core::Engine.routes.draw do
  namespace :admin do
    # All admin routes
  end
  
  namespace :api do
    # All API routes
  end
  
  # All storefront routes
end
```

### Pattern: ActiveAdmin

```ruby
# activeadmin/config/routes.rb
ActiveAdmin.routes(self) do
  # DSL generates all routes
end
```

### Sandbox/Demo App Pattern (Universal)

Every engine provides sandbox/demo app with its own routes:

```ruby
# sandbox/config/routes.rb (generated, not copied)
Rails.application.routes.draw do
  # Application-specific routes (health checks, Devise, etc.)
  devise_for :users if defined?(Devise)
  
  # Mount engine at chosen path
  mount Oroshi::Engine => "/oroshi", as: 'oroshi'
  
  root to: redirect('/oroshi')
end
```

**Key Point:** Sandbox routes are GENERATED, not copied from gem.

---

## Proposed Solution: Single Route File

### New File Structure

```
config/
├── routes.rb                      # ONLY route file
├── routes_oroshi_engine.rb        # Documentation (rename to .example)
└── routes.rb.engine               # Documentation (rename to .example)
```

### New routes.rb

```ruby
# Engine routes - the ONLY route file
# When Oroshi is mounted in a host application, these routes become
# available under the mount path (e.g., /oroshi if mounted there)
#
# Example in host app:
#   Rails.application.routes.draw do
#     mount Oroshi::Engine => "/oroshi"
#   end
#
# Routes then available at:
#   /oroshi              -> Oroshi::DashboardController#show
#   /oroshi/products     -> Oroshi::ProductsController#index
#   etc.
#
Oroshi::Engine.routes.draw do
  # Dashboard
  root to: "dashboard#show"
  resource :dashboard, only: [:show]
  
  # Product management
  resources :stores, shallow: true do
    resources :products do
      member do
        post :duplicate
      end
    end
  end
  
  # Order management
  resources :orders do
    member do
      post :submit
      post :approve
      post :reject
    end
    resources :order_items, only: [:create, :update, :destroy]
  end
  
  # Variant management
  resources :product_variant_groups
  resources :product_variants
  
  # User management
  resources :users, only: [:index, :show]
end
```

### New bin/sandbox Script

```bash
#!/usr/bin/env ruby

# Generate sandbox routes file (not copy from gem)
routes_content = <<~ROUTES
  Rails.application.routes.draw do
    # Devise authentication
    devise_for :users, class_name: 'Oroshi::User'
    
    # Mount Oroshi engine
    mount Oroshi::Engine => "/oroshi", as: 'oroshi'
    
    # Health check
    get "up" => "rails/health#show", as: :rails_health_check
    
    # Default root
    root to: redirect('/oroshi')
  end
ROUTES

File.write('sandbox/config/routes.rb', routes_content)
```

### Test Environment Changes

No changes needed! Tests automatically use engine routes.

**Before (broken):**
```ruby
# test/test_helper.rb
require_relative "../config/routes_standalone_app" # PROBLEM
```

**After (works):**
```ruby
# test/test_helper.rb
# No route loading needed - engine routes loaded automatically
```

---

## Migration Plan

### Phase 1: Backup & Branch (5 min)
```bash
git checkout -b refactor/installation-testing
git add -A && git commit -m "Checkpoint before route refactoring"
```

### Phase 2: Remove Standalone Routes (10 min)
```bash
rm config/routes_standalone_app.rb
git add config/routes_standalone_app.rb
```

### Phase 3: Update routes.rb (15 min)
- Add Devise routes to engine (if needed for tests)
- Add comprehensive comments explaining pattern
- Keep all existing engine routes

### Phase 4: Update bin/sandbox (10 min)
- Generate routes.rb instead of copying
- Include Devise configuration
- Include engine mount
- Include health check

### Phase 5: Update Tests (20 min)
- Remove any loading of `routes_standalone_app.rb`
- Verify tests use `oroshi.*` helpers
- Run full test suite
- Fix any failures

### Phase 6: Test oroshi-moab (15 min)
- Update oroshi-moab Gemfile to use local path
- Run `bundle install`
- Run `rails db:migrate`
- Start server and test

### Phase 7: Documentation (20 min)
- Update README.md
- Update CLAUDE.md
- Update .ralph/prompt.md
- Add REALIZATIONS.md entry

**Total Estimated Time:** 1.5-2 hours

---

## Trade-offs Analysis

### Advantages of Single Route File

✅ **Follows Rails Conventions**
- Industry standard pattern
- Easier for contributors to understand
- Documented in Rails guides

✅ **Fixes Asset Loading**
- Clear namespace separation
- No routing conflicts
- Assets resolve correctly

✅ **Enables Gemification**
- Can be installed in other apps
- No namespace collisions
- Works with standard mounting

✅ **Simplifies Testing**
- Tests use engine routes directly
- No standalone route loading
- Clearer test failures

✅ **Reduces Maintenance**
- One file to update
- No synchronization issues
- Clear ownership

### Disadvantages of Single Route File

⚠️ **Standalone Development Changes**
- Sandbox becomes separate app (already is!)
- Must regenerate sandbox when testing (already required!)
- Different from "mountable app" pattern (but we're an engine!)

⚠️ **Devise Integration**
- Need to decide: Devise in engine or application?
- Current approach: Devise in engine for tests, application for real use
- Solution: Document both approaches

### Decision

The advantages VASTLY outweigh the disadvantages. The "disadvantages" are actually just acknowledging that we're properly following the Rails engine pattern.

---

## Routing Patterns in Engine Context

### Pattern 1: Engine-Scoped Routes (CHOSEN)

**Best For:** Oroshi (wholesale management as plugin)

```ruby
# config/routes.rb
Oroshi::Engine.routes.draw do
  resources :products
  resources :orders
end

# Host app mounts:
# mount Oroshi::Engine => "/wholesale"
#
# Routes available at:
# /wholesale/products
# /wholesale/orders
```

**Advantages:**
- Clear namespace separation
- Multiple engines can coexist
- Engine routes isolated from app routes
- Easy to reason about paths

**Disadvantages:**
- Always requires mount path
- Can't mount at root easily (but that's rare for engines)

### Pattern 2: Application Routes (NOT RECOMMENDED)

**Best For:** Plugins that extend app routing (like Devise)

```ruby
# Don't do this for Oroshi
Rails.application.routes.draw do
  resources :products # Pollutes application namespace
end
```

**Why Oroshi Shouldn't Use This:**
- We're not a routing DSL like Devise
- We're a complete subsystem
- Namespace pollution
- Can't be mounted at custom paths

---

## Asset Path Resolution

### How Engine Assets Work

When engine is mounted at `/oroshi`:

```erb
<!-- In engine view -->
<%= link_to "Products", oroshi.products_path %>
<!-- Generates: /oroshi/products -->

<%= image_tag "oroshi/logo.png" %>
<!-- Asset pipeline finds: app/assets/images/oroshi/logo.png -->

<%= stylesheet_link_tag "oroshi/application" %>
<!-- Asset pipeline finds: app/assets/stylesheets/oroshi/application.css -->
```

### Accessing Host App Routes from Engine

```erb
<!-- In engine view, link to host app -->
<%= link_to "Home", main_app.root_path %>
<!-- Uses host application's root route -->
```

### Why Dual Routes Broke This

```ruby
# routes_standalone_app.rb mounted engine at "/"
mount Oroshi::Engine => "/"

# This made oroshi.products_path resolve to:
# /products (incorrect, conflicts with potential app routes)

# Instead of:
# /oroshi/products (correct, namespaced)
```

Tests failed because:
1. Standalone routes mounted at "/"
2. Engine routes expected to be at "/oroshi" (or some prefix)
3. Asset paths calculated incorrectly
4. JavaScript/CSS not found

---

## Testing Strategy After Migration

### System Tests

```ruby
# test/system/products_test.rb
class ProductsTest < ApplicationSystemTestCase
  test "visiting products index" do
    visit oroshi.products_path # Uses engine routes
    assert_selector "h1", text: "Products"
  end
end
```

### Integration Tests

```ruby
# test/integration/products_test.rb
class ProductsTest < ActionDispatch::IntegrationTest
  test "GET /products" do
    get oroshi.products_path # Uses engine routes
    assert_response :success
  end
end
```

### Routing Tests

```ruby
# test/routing/routes_test.rb
class RoutesTest < ActionDispatch::IntegrationTest
  test "routes to dashboard" do
    assert_generates "/", { controller: "oroshi/dashboard", action: "show" }
  end
end
```

---

## Documentation Requirements

### README.md

Add section:

```markdown
## Routing Architecture

Oroshi is a Rails engine with its own route namespace. When mounted in your application:

```ruby
# config/routes.rb
mount Oroshi::Engine => "/oroshi"
```

All Oroshi routes become available under `/oroshi`:
- `/oroshi` - Dashboard
- `/oroshi/products` - Product listing
- `/oroshi/orders` - Order management

### Accessing Oroshi Routes in Views

```erb
<%= link_to "Products", oroshi.products_path %>
```

### Accessing Host App Routes from Oroshi Views

```erb
<%= link_to "Home", main_app.root_path %>
```
```

### CLAUDE.md

Add section:

```markdown
## Route Configuration

CRITICAL: Oroshi uses a **single route file** pattern (config/routes.rb).

DO NOT create routes_standalone_app.rb or similar. This pattern:
- Breaks asset loading
- Prevents gemification
- Is non-standard
- Causes namespace conflicts

All routes are in Oroshi::Engine.routes.draw block.
```

### .ralph/prompt.md

Already updated with this pattern.

---

## Verification Checklist

After migration:

- [ ] Only one route file exists: `config/routes.rb`
- [ ] All routes in `Oroshi::Engine.routes.draw` block
- [ ] Sandbox generates its own routes file
- [ ] All tests pass (`rails test`)
- [ ] All system tests pass (`rails test:system`)
- [ ] oroshi-moab installation works
- [ ] Assets load in oroshi-moab
- [ ] No console errors in oroshi-moab
- [ ] Documentation updated
- [ ] Git commit with clear message

---

## Future Considerations

### Multi-Database Routes

Oroshi uses 4 databases. Routes work the same:

```ruby
Oroshi::Engine.routes.draw do
  # Routes use default database (main)
  # Solid Queue/Cache/Cable configured in initializers, not routes
end
```

### API Endpoints

If adding API:

```ruby
Oroshi::Engine.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :products
    end
  end
end

# Available at: /oroshi/api/v1/products
```

### Sub-Engines

If adding sub-engines (unlikely):

```ruby
Oroshi::Engine.routes.draw do
  mount Oroshi::Reporting::Engine => "/reporting"
end

# Available at: /oroshi/reporting/*
```

---

## References

- Rails Engines Guide: https://guides.rubyonrails.org/engines.html
- Solidus routing: https://github.com/solidusio/solidus/blob/main/core/config/routes.rb
- Devise routing: https://github.com/heartcombo/devise/blob/main/config/routes.rb
- Research findings: `docs/research/findings-gem-installation-testing.md`
- Gap analysis: `docs/research/oroshi-installation-gaps.md`
