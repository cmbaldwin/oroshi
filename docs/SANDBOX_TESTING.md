# Sandbox Architecture & Testing Guide

This guide details the architecture of the `bin/sandbox` script and the patterns used to generate a reliable, production-like Rails 8 development environment for the Oroshi engine.

## Overview

The sandbox is a throwaway Rails application generated on-demand to test the Oroshi engine. It mirrors the production environment but is optimized for development speed and reliability.

**Key Features:**
- **Rails 8.1**: Uses the latest Rails conventions.
- **Engine Isolation**: Properly mounts Oroshi engine at `/oroshi`.
- **Propshaft + CDN**: Simplified asset pipeline avoiding Node.js complexity in development.
- **Multi-Database**: Configures Primary, Queue, Cache, and Cable databases.
- **Solid Gems**: Pre-configures Solid Queue, Solid Cache, and Solid Cable.

---

## 🏗️ Sandbox Creation Architecture

The `bin/sandbox` script orchestrates the creation process. Here is the architectural breakdown:

### 1. Engine Isolation & Routing
Typical engines struggle with path helpers when mounted. We solve this by:

**A. Injecting Helpers into Host Controller**
To allow the host application (`sandbox`) to use engine routes (like `privacy_policy_path` in the footer), we inject the helper module directly into the host's `ApplicationController`:

```ruby
# bin/sandbox
sed -i '' 's/class ApplicationController/class ApplicationController ... helper Oroshi::Engine.routes.url_helpers/' ...
```

**B. Scoping Devise Routes (`main_app`)**
Since the navbar partial (`layouts/shared/_navbar`) lives in the engine but renders links to Devise (which lives in the host app), we must prefix routes with `main_app`:

```erb
<%= link_to "Login", main_app.new_user_session_path %>
```

### 2. Asset Management (CDN + Propshaft)
To avoid the complexity of `cssbundling-rails` or `jsbundling-rails` (Node.js, esbuild, Tailwind builds) in a generated sandbox, we use a simpler approach:

**A. Bootstrap via CDN**
We inject standard Bootstrap 5 and Icon CDNs directly into the layout. This ensures the UI looks correct without a build step.

**B. Propshaft for Custom CSS**
We use `propshaft` to serve the engine's custom styles (`oroshi.css`). The script copies the pre-built CSS from the gem to the sandbox:

```bash
cp ../app/assets/builds/oroshi.css app/assets/builds/
```

### 3. Database Initialization Strategy
Initializing a Rails app with a complex engine is prone to "Chicken and Egg" problems.

**A. Conditional Initializers**
Gem initializers can crash `db:create` if tables don't exist. We wrap them:

```ruby
if defined?(Carmen)
  # configure
end
```

**B. Minimal User Model**
Migrations often reference the `User` model. If `User` loads Devise before the database exists, it crashes.
**Solution:**
1. Create a minimal `User` class (no Devise).
2. Run database setup.
3. Replace with full Devise `User` model.

**C. Schema Loading**
We use `db:schema:load` instead of `db:migrate`. This prevents migration files (which might reference app code) from executing during setup.

---

## 👩‍💻 Development Workflow

### Starting the Sandbox
Always use `bin/dev` to ensure services start correctly:

```bash
cd sandbox
bin/dev
```

This starts:
1. **Web Server** (Puma on port 3000)
2. **Solid Queue** (Background jobs)
3. **CSS Watcher** (if configured, though sandbox uses CDN)

### Verification
When the sandbox is running, verify:
1. **Login Page**: http://localhost:3000/users/sign_in (Should show navbar)
2. **Dashboard**: http://localhost:3000/oroshi (Should require login)
3. **Footer Links**: Privacy Policy (Should work via Engine route)

---

## 🧪 E2E Testing

We support automated end-to-end testing of the sandbox generation process:

```bash
rake sandbox:test
```

This task:
1. Destroys existing sandbox.
2. Runs `bin/sandbox` to generate a fresh one.
3. Boots the server.
4. Runs browser-based tests (Capybara/Selenium) to verify:
   - Login flow
   - Order creation
   - PDF generation
5. Tears down the environment.

See `test/sandbox_e2e_test.rb` for implementation details.
