# Ralph Realizations

Quick reference for patterns, gotchas, and constraints discovered during development.

<!--
Entry Format Template:
## [Category] - [Short Title]

**Problem:** What was going wrong or could go wrong
**Solution:** How to fix or avoid it
**Code Example:**
```ruby
# Example code here
```
**Gotcha:** Any non-obvious edge cases
**Related:** Links to relevant files or documentation
-->

## Table of Contents

- [Rails & ActiveRecord](#rails--activerecord)
- [Turbo & Stimulus](#turbo--stimulus)
- [Testing](#testing)
- [Database & Migrations](#database--migrations)
- [Asset Pipeline](#asset-pipeline)
- [Internationalization](#internationalization)
- [Authentication & Authorization](#authentication--authorization)
- [Background Jobs](#background-jobs)

---

## Rails & ActiveRecord

*Entries for ActiveRecord patterns, model callbacks, associations, and query gotchas.*

### User.insert vs User.create! for Devise Users

**Problem:** When creating seeded or demo users with Devise, using `User.create!` triggers ActiveRecord callbacks including Devise's `send_confirmation_instructions` callback, which sends confirmation emails even when `confirmed_at` is already set.

**Solution:** Use `User.insert` to skip all ActiveRecord callbacks, including Devise's email-sending callbacks. This requires manually setting all required fields including `encrypted_password`, `role`, timestamps, and `confirmed_at`.

**Code Example:**
```ruby
# Skip Devise callbacks by using insert instead of create!
User.insert({
  email: 'admin@oroshi.local',
  username: 'admin',
  encrypted_password: Devise::Encryptor.digest(User, 'password123'),
  role: User.roles[:admin],          # Use enum integer value
  confirmed_at: Time.current,
  created_at: Time.current,
  updated_at: Time.current
})
```

**Gotcha:** `User.insert` returns the number of inserted rows, not the User object. If you need the created user, query for it afterward. Also, enum fields must use their integer values (e.g., `User.roles[:admin]`).

**Related:** `bin/sandbox` lines 391-419, `db/seeds.rb`

---

### HABTM Strong Params Array Syntax

**Problem:** When permitting `has_and_belongs_to_many` association IDs in strong parameters, forgetting the array bracket syntax (`association_ids: []`) causes Rails to only accept a single ID value, not an array. This breaks forms with multi-select checkboxes or select tags, silently discarding all but the last selected value.

**Solution:** Always use the array syntax `association_ids: []` when permitting HABTM or `has_many` association IDs in strong parameters.

**Code Example:**
```ruby
# CORRECT - Array syntax for HABTM associations
def product_params
  params.require(:oroshi_product)
        .permit(:name, :units, :supply_type_id, :tax_rate,
                material_ids: [])  # Array of IDs for has_and_belongs_to_many :materials
end

def supplier_params
  params.require(:oroshi_supplier)
        .permit(:entity_name, :invoice_name, :active,
                supply_type_variation_ids: [],  # HABTM array
                supply_date_ids: [])            # HABTM array
end

# WRONG - Without brackets (only accepts single value)
def product_params
  params.require(:oroshi_product)
        .permit(:name, material_ids)  # ERROR: Will only accept one material_id
end
```

**Common HABTM Patterns in Oroshi:**
```ruby
# Supplier ↔ SupplyTypeVariation
supply_type_variation_ids: []

# SupplierOrganization ↔ SupplyReceptionTime
supply_reception_time_ids: []

# Product ↔ Material
material_ids: []

# ProductVariation ↔ ProductionZone
production_zone_ids: []

# Buyer ↔ ShippingMethod
shipping_method_ids: []  # (if exists)
```

**Gotcha:** The error is silent - Rails doesn't raise an exception when you forget the brackets. It just accepts the last value from the array and discards the rest. Debug by checking `params` in console: if you send `[1, 2, 3]` but receive `"3"` as a string, you forgot the `[]` syntax.

**Related:** `app/controllers/oroshi/products_controller.rb` line 103, `app/controllers/oroshi/suppliers_controller.rb` line 70, `app/controllers/oroshi/onboarding_controller.rb` lines 208, 236, 281

---

## Turbo & Stimulus

*Entries for Turbo Frames, Turbo Streams, Stimulus controllers, and Hotwire patterns.*

### Turbo Frame Lazy Loading Pattern

**Problem:** Loading all content on initial page load can be slow. Turbo Frames support deferred loading, but if implemented incorrectly, you'll see a "Content missing" error when the frame's ID doesn't match between the requesting frame and the response.

**Solution:** Use `src:` combined with `loading: 'lazy'` to defer content loading until the frame scrolls into view. The response MUST contain a `turbo_frame_tag` with the exact same ID.

**Code Example:**
```erb
<%# In the parent view - request deferred content %>
<%= turbo_frame_tag dom_id(invoice), src: invoice_path(invoice), loading: 'lazy' do %>
  <div class="placeholder">Loading...</div>
<% end %>

<%# In the partial/show response - frame ID must match %>
<%= turbo_frame_tag dom_id(@invoice) do %>
  <div class="invoice-details">
    <%= @invoice.number %>
  </div>
<% end %>
```

**Common Patterns:**
```erb
<%# List items with lazy loading %>
<% @orders.each do |order| %>
  <%= turbo_frame_tag dom_id(order), src: edit_oroshi_order_path(order), loading: 'lazy' do %>
    <div class="spinner-border"></div>
  <% end %>
<% end %>

<%# Modal content lazy loading %>
<%= turbo_frame_tag 'oroshi_modal_content', src: new_oroshi_buyer_path do %>
  <div>Loading form...</div>
<% end %>
```

**Gotcha:** The "Content missing" error means the response HTML doesn't contain a `turbo_frame_tag` with a matching ID. Debug by: 1) checking the response contains the frame, 2) verifying IDs match exactly (case-sensitive), 3) ensuring the controller renders the correct view/partial.

**Related:** `app/views/oroshi/invoices/index.html.erb`, `app/views/oroshi/orders/_order.html.erb`

---

### Bootstrap Modal + Turbo Frame Integration

**Problem:** Integrating Bootstrap 5 modals with Turbo Frames requires coordinating three things: 1) link that opens modal, 2) turbo frame that loads content, 3) controller response that renders into frame. Miss any piece and you get blank modals or "Content missing" errors.

**Solution:** Use `data-turbo-frame` on the link to target the frame inside the modal, and ensure the controller response renders a matching turbo_frame_tag. Use a Stimulus controller to trigger Bootstrap's modal show/hide.

**Code Example:**
```erb
<%# Step 1: Modal container with turbo frame %>
<div class="modal fade" id="oroshiModal" tabindex="-1">
  <div class="modal-dialog">
    <%= turbo_frame_tag 'oroshi_modal_content', class: 'modal-content' do %>
      <div class="modal-body">
        <p>Loading...</p>
      </div>
    <% end %>
  </div>
</div>

<%# Step 2: Link that opens modal and loads content %>
<%= link_to t('oroshi.dashboard.add_record'),
            new_oroshi_buyer_path,
            class: 'btn btn-sm btn-success',
            data: {
              turbo_frame: 'oroshi_modal_content',        # Load response into this frame
              action: 'oroshi--dashboard#showModal:passive' # Trigger Bootstrap modal.show()
            } %>

<%# Step 3: Controller response with matching frame %>
<%# app/views/oroshi/buyers/new.html.erb %>
<%= turbo_frame_tag 'oroshi_modal_content', class: 'modal-content' do %>
  <div class="modal-header">
    <h5 class="modal-title"><%= t('.title') %></h5>
    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
  </div>
  <div class="modal-body">
    <%= render 'form', buyer: @buyer %>
  </div>
<% end %>
```

**Stimulus Controller Pattern:**
```javascript
// app/javascript/controllers/oroshi/dashboard_controller.js
showModal() {
  const modal = this.modalTarget  // data-oroshi--dashboard-target="modal"
  const bsModal = new bootstrap.Modal(modal)
  bsModal.show()
}
```

**Form Handling in Modals:**
```erb
<%# Option 1: Disable Turbo for standard form submission %>
<%= form_with model: @buyer, data: { turbo: false } do |f| %>
  ...
<% end %>

<%# Option 2: Handle Turbo submission with redirect or turbo_stream %>
<%# In controller %>
def create
  if @buyer.save
    redirect_to oroshi_buyers_path, notice: 'Success'  # Closes modal
    # OR
    respond_to do |format|
      format.turbo_stream  # Use turbo_stream to update page and close modal
    end
  end
end
```

**Gotcha:** Don't forget to include the Stimulus action (`data: { action: '...' }`) to trigger the modal show. Just setting `data-turbo-frame` loads the content but doesn't open the modal. Also, ensure frame IDs match exactly between link target and response frame.

**Related:** `app/views/oroshi/dashboard/_oroshi_modal.html.erb`, `app/views/oroshi/buyers/index.html.erb` lines 47-53, `app/views/oroshi/buyers/new.html.erb`

---

## Testing

*Entries for Test::Unit patterns, system tests, factories, and test setup.*

### Test::Unit Framework (NOT RSpec)

**Problem:** Oroshi uses Test::Unit (Minitest) as its testing framework, but developers familiar with RSpec may accidentally use RSpec syntax (`describe`, `it`, `expect`) or commands (`bundle exec rspec`).

**Solution:** Always use Test::Unit syntax and Rails test commands. Tests go in `test/` directory, not `spec/`.

**Code Example:**
```ruby
# CORRECT - Test::Unit syntax
class ProductTest < ActiveSupport::TestCase
  test "should validate presence of name" do
    product = Oroshi::Product.new
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end
end

# WRONG - RSpec syntax (DO NOT USE)
describe Product do
  it "validates presence of name" do
    expect(Product.new).to be_invalid
  end
end
```

**Commands:**
```bash
# CORRECT
bin/rails test                           # Run all tests
bin/rails test test/models/              # Run model tests
bin/rails test test/models/product_test.rb  # Run specific file
bin/rails test test/models/product_test.rb:15  # Run specific line

# WRONG
bundle exec rspec                        # Will fail - RSpec not installed
```

**Gotcha:** Factory Bot is still used (`FactoryBot.create`), but assertions use `assert_*` methods, not `expect().to`. System tests use Capybara matchers with `assert_selector`, `assert_text`, etc.

**Related:** `test/` directory structure, CLAUDE.md Testing section

---

### System Test Setup with JavaScript Support

**Problem:** System tests in Rails can run with or without JavaScript support. Tests without JavaScript (rack_test) are faster but can't test Stimulus controllers, Turbo Frames, or modals. Tests with JavaScript (Selenium) are slower but required for interactive features. Knowing when to use which driver prevents slow test suites.

**Solution:** Use the `JavaScriptTest` module for tests that require browser JavaScript support. For non-interactive tests, inherit from `ApplicationSystemTestCase` directly which uses the faster rack_test driver.

**Code Example:**
```ruby
# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers
  
  # Default: fast rack_test driver (no JS)
  driven_by :rack_test
  
  Capybara.default_max_wait_time = 3
end

# Helper module for JS tests
module JavaScriptTest
  def self.included(base)
    base.class_eval do
      driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |options|
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")
      end
    end
  end
end

# Test WITH JavaScript (Turbo Frames, modals, Stimulus)
class OroshiDashboardTest < ApplicationSystemTestCase
  include JavaScriptTest  # Enables Selenium/headless Chrome
  
  setup do
    @admin = create(:user, :admin)
    sign_in @admin  # Devise helper
    I18n.locale = :ja  # Default locale for tests
  end
  
  test "loads dashboard with turbo frames" do
    visit oroshi_root_path
    assert_selector "turbo-frame#dashboard_content", wait: 10
  end
end

# Test WITHOUT JavaScript (faster for simple page loads)
class OroshiNavigationTest < ApplicationSystemTestCase
  # No JavaScriptTest module - uses rack_test
  
  setup do
    @user = create(:user)
    sign_in @user
  end
  
  test "visits about page" do
    visit about_path
    assert_text "About Oroshi"
  end
end
```

**When to Include JavaScriptTest:**
```ruby
# INCLUDE JavaScriptTest for:
# - Turbo Frame interactions
# - Modal opening/closing
# - Stimulus controller behaviors
# - JavaScript-triggered events
# - AJAX requests
# - Real-time updates

# DON'T INCLUDE for:
# - Simple page visits
# - Form submissions (without Turbo)
# - Link clicking (standard navigation)
# - Static content verification
```

**Gotcha:** Including `JavaScriptTest` makes tests ~10x slower because Selenium starts a real browser. Only use it when necessary. The `sign_in` helper comes from `Devise::Test::IntegrationHelpers` included in `ApplicationSystemTestCase`. Default locale is `:ja` for Japanese-first testing.

**Related:** `test/application_system_test_case.rb`, `test/system/oroshi/dashboard_test.rb` lines 1-11

---

## Database & Migrations

*Entries for multi-database setup, schema loading, and migration patterns.*

### Schema Loading vs Migration for Fresh Databases

**Problem:** When setting up fresh databases (sandbox creation, CI/CD, demo apps), running `db:migrate` can fail because migration files may execute model code that references `Oroshi::` namespaced models before the engine is fully initialized.

**Solution:** Use `db:schema:load` instead of `db:migrate` for fresh database setups. Schema loading creates tables directly from `schema.rb` without executing migration code.

**Code Example:**
```bash
# CORRECT - For fresh databases (sandbox, CI, demo apps)
bin/rails db:create
bin/rails db:schema:load            # Main database
bin/rails db:schema:load:queue      # Solid Queue database
bin/rails db:schema:load:cache      # Solid Cache database
bin/rails db:schema:load:cable      # Solid Cable database

# WRONG - For fresh databases (may fail during engine initialization)
bin/rails db:create
bin/rails db:migrate
```

**When to Use Each:**
```bash
# db:schema:load - Use for:
# - Sandbox creation
# - CI/CD pipelines
# - New development environments
# - Demo app setup
# - Any fresh database without existing data

# db:migrate - Use for:
# - Production deployments (existing data)
# - Adding new migrations to existing database
# - Development when you have existing data
```

**Gotcha:** `db:schema:load` destroys existing data! Only use on fresh databases. For production deployments with existing data, always use `db:migrate`. The sandbox script and CI workflow both use `db:schema:load` because they start from empty databases.

**Related:** `bin/sandbox` lines 333-343, `.github/workflows/ci.yml`, CLAUDE.md Sandbox section

---

### Conditional Gem Initializers for Database Tasks

**Problem:** When running `db:create` or `db:migrate`, Rails loads initializers before gems are fully loaded. This causes `uninitialized constant` errors if initializers reference gem classes (Carmen, Devise, SimpleForm, Resend, Bullet, etc.).

**Solution:** Wrap all gem-specific configuration in conditional checks using `if defined?(GemName)`. This ensures the initializer only executes when the gem is fully loaded.

**Code Example:**
```ruby
# config/initializers/carmen.rb
# CORRECT - Conditional initialization
if defined?(Carmen)
  Carmen.i18n_backend.locale = :ja
  Carmen::Country.all.each do |country|
    country.instance_variable_set(:@name, country.translations[:ja])
  end
end

# config/initializers/devise.rb
if defined?(Devise)
  Devise.setup do |config|
    config.secret_key = Rails.application.credentials.secret_key_base
    config.mailer_sender = 'noreply@example.com'
    # ... rest of config
  end
end

# WRONG - Direct initialization (will fail during db:create)
Carmen.i18n_backend.locale = :ja  # Error: uninitialized constant Carmen
```

**When This Matters:**
```bash
# These commands load initializers before gems are ready:
bin/rails db:create          # Gems not loaded yet
bin/rails db:migrate         # May fail during migration execution
bin/rails db:schema:load     # Loads initializers first

# Safe - gems fully loaded:
bin/rails console           # All gems loaded
bin/rails server            # Full initialization
bin/rails test              # Test environment gems loaded
```

**Gotcha:** Don't assume any gem is available during database tasks. Even standard gems like Devise, FactoryBot, or Bullet can fail. Always use `if defined?(GemName)` for gem-specific initializers.

**Related:** `bin/sandbox` lines 280-350 (all gem initializers wrapped), CLAUDE.md Sandbox section

---

## Asset Pipeline

*Entries for Propshaft, importmap, Tailwind, and font handling.*

---

## Internationalization

*Entries for i18n patterns, Japanese-first UI, and locale files.*

### Japanese-First i18n Approach

**Problem:** Oroshi is a Japanese-first application. All user-facing text MUST be translatable via i18n. Hardcoded English (or any language) strings in views violate the project's localization requirements.

**Solution:** Always use `t()` helper for all UI text. Never hardcode strings like "Save", "Cancel", "Back", or "Skip for now". Use lazy lookup in views (`t('.key')`) and full paths in controllers/jobs.

**Code Example:**
```erb
<%# CORRECT - Always use t() helper %>
<h2><%= t('.title') %></h2>
<p><%= t('.description') %></p>
<%= link_to t('common.buttons.back'), :back %>
<%= submit_tag t('common.buttons.save') %>

<%# WRONG - Never hardcode strings %>
<h2>Settings</h2>
<p>Configure your preferences below.</p>
<%= link_to "Back", :back %>
<%= submit_tag "Save" %>
```

**Namespace Convention:**
```yaml
# config/locales/ja.yml
ja:
  oroshi:
    namespace:
      view_name:
        title: "タイトル"
        description: "説明文"
    common:
      buttons:
        save: "保存"
        cancel: "キャンセル"
        back: "戻る"
        next: "次へ"
        skip: "スキップ"
```

**Lazy Lookup:**
```erb
<%# In app/views/oroshi/onboarding/steps/_supplier_organization.html.erb %>
<%= t('.title') %>
<%# Translates to: oroshi.onboarding.steps.supplier_organization.title %>
```

**Gotcha:** When adding new UI text, always add the Japanese translation first. The i18n key should exist before using it. Use `I18n.t('key', default: 'fallback')` only for development/debugging, never in production code.

**Related:** CLAUDE.md Internationalization section, `config/locales/` directory

---

## Authentication & Authorization

*Entries for Devise configuration, user model patterns, and access control.*

---

## Background Jobs

*Entries for Solid Queue patterns, job configuration, and recurring tasks.*

---

*Last Updated: January 25, 2026*
