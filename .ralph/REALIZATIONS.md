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

## Database & Migrations

*Entries for multi-database setup, schema loading, and migration patterns.*

---

## Asset Pipeline

*Entries for Propshaft, importmap, Tailwind, and font handling.*

---

## Internationalization

*Entries for i18n patterns, Japanese-first UI, and locale files.*

---

## Authentication & Authorization

*Entries for Devise configuration, user model patterns, and access control.*

---

## Background Jobs

*Entries for Solid Queue patterns, job configuration, and recurring tasks.*

---

*Last Updated: January 25, 2026*
