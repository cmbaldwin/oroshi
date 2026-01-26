# Oroshi - Wholesale Order Management Rails Engine

> **⚠️ Development Status**: This project is under heavy active development. The sandbox currently works but has lots of bugs that are being worked through slowly.
>
> **Most Stable Version**: For the most stable version, use the branch before gemification at commit `13265f7ca5e642163e1c072dc9b88283983ad693` ("Merge branch 'ralph/user-onboarding'")

A comprehensive wholesale order management system packaged as a Rails engine gem. Built with Ruby on Rails 8.1.1 for Japanese food distribution businesses.

## Features

- **Order Management**: Complete order lifecycle from creation to fulfillment
- **Supply Tracking**: Multi-user supply entry and verification
- **Document Generation**: Automated invoices, packing lists, and reports (PDF with Japanese fonts)
- **Real-time Updates**: Turbo Streams with Solid Cable for live order updates
- **Background Jobs**: Solid Queue for email delivery and async processing
- **Customer Management**: Account management with delivery address tracking
- **Multi-Database Architecture**: Separated databases for primary, queue, cache, and cable
- **Japanese-First Design**: Complete Japanese localization (i18n) with Asia/Tokyo timezone

## Tech Stack

- **Ruby** 4.0.0
- **Rails** 8.1.1
- **Database**: PostgreSQL 16 (4-database architecture)
- **Testing**: Minitest (539 passing examples)
- **Background Jobs**: Solid Queue
- **Real-time**: Solid Cable (WebSockets via PostgreSQL)
- **Caching**: Solid Cache
- **Authentication**: Devise
- **Frontend**: Hotwire (Turbo + Stimulus) + Bootstrap 5
- **Assets**: Propshaft + Importmap (no Node.js required)
- **PDF Generation**: Prawn with Japanese fonts (MPLUS1p, Sawarabi, TakaoPMincho)

## Quick Start (3 Commands)

### For New Rails Applications

```bash
# 1. Create a new Rails app
rails new my_oroshi_app --database=postgresql
cd my_oroshi_app

# 2. Add Oroshi gem and install
echo 'gem "oroshi", path: "path/to/oroshi"' >> Gemfile  # Or gem "oroshi" for published gem
bundle install
rails generate oroshi:install

# 3. Setup and start
bin/rails db:setup
bin/rails server
```

Visit http://localhost:3000 and sign in with the demo admin account.

### For Existing Rails Applications

```bash
# 1. Add to Gemfile
gem "oroshi", path: "path/to/oroshi"  # Or gem "oroshi" for published gem
bundle install

# 2. Run install generator
rails generate oroshi:install

# 3. Setup databases
bin/rails db:create db:migrate
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable

# 4. (Optional) Seed demo data
bin/rails db:seed

# 5. Start server
bin/rails server
```

## Installation Details

### What the Install Generator Does

Running `rails generate oroshi:install` will:

1. **Create Oroshi initializer** (`config/initializers/oroshi.rb`)
   - Configures timezone, locale, and domain

2. **Create User model** (`app/models/user.rb`)
   - Devise-based authentication
   - Role-based access (user, vip, admin, supplier, employee)

3. **Mount Oroshi engine** in routes
   - Makes all Oroshi routes available at "/"

4. **Copy migrations** from the engine
   - All Oroshi models and associations

5. **Copy Solid schemas** (queue, cache, cable)
   - Database schemas for background jobs, caching, and WebSockets

### Configuration

After installation, configure Oroshi in `config/initializers/oroshi.rb`:

```ruby
Oroshi.configure do |config|
  # Application timezone (Japanese time zone by default)
  config.time_zone = "Asia/Tokyo"

  # Default locale (Japanese by default)
  config.locale = :ja

  # Application domain (for URL generation)
  config.domain = ENV.fetch("OROSHI_DOMAIN", "localhost")
end
```

### Multi-Database Setup

Oroshi requires a 4-database PostgreSQL setup. Update `config/database.yml`:

```yaml
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

## Sandbox Application

A fully-functional demo application can be generated for testing and development:

```bash
# Generate sandbox application
bin/sandbox

# Start the sandbox
cd sandbox
bin/dev
```

**Important:** Always use `bin/dev` (not `bin/rails server`) to ensure CSS compilation runs alongside the web server.

The sandbox demonstrates complete Oroshi integration with:

- **3 demo users** (admin, VIP, regular) - all password: `password123`
- **Complete master data** (suppliers, products, buyers, shipping methods)
- **Multi-database setup** (primary, queue, cache, cable)
- **Bootstrap 5 CDN** (no build step required)
- **Propshaft** asset serving (no complex pipeline)
- **Minimal configuration** (generated automatically)

### How Sandbox Creation Works

The sandbox script uses a carefully orchestrated process to avoid initialization errors:

1. **Generates Rails app** in temporary directory (to avoid "Rails within Rails" errors)
2. **Installs Oroshi gem** and dependencies
3. **Creates conditional initializers** (wrapped in `if defined?` checks)
4. **Copies migrations** directly from engine
5. **Creates minimal User model** (for migration compatibility)
6. **Uses schema:load** instead of db:migrate (avoids migration code execution issues)
7. **Replaces with full User model** after database setup
8. **Seeds demo data** with realistic examples

This approach ensures reliable sandbox creation even when gems have complex initialization requirements.

### Demo Accounts

- **Admin**: `admin@oroshi.local` / `password123` - Full system access
- **VIP**: `vip@oroshi.local` / `password123` - Dashboard and orders
- **Regular**: `user@oroshi.local` / `password123` - Limited access

### Sandbox Commands

```bash
bin/sandbox              # Create sandbox (default)
bin/sandbox reset        # Destroy and recreate
bin/sandbox destroy      # Remove sandbox
bin/sandbox help         # Show all commands

# Use different database
DB=mysql bin/sandbox     # Create with MySQL instead of PostgreSQL
```

## Onboarding

New users are guided through a step-by-step onboarding wizard to set up:

1. **Company Information** - Business details and invoice settings
2. **Supply Chain** - Reception times, supplier organizations, suppliers, supply types
3. **Sales** - Buyers and products with variations
4. **Shipping** - Organizations, methods, receptacles, and order categories

The wizard can be skipped and resumed later via a persistent checklist sidebar.

## Development

### Running Tests

```bash
# Run full test suite (539 examples)
bin/rails test

# Run specific test file
bin/rails test test/models/oroshi/order_test.rb

# Run system tests
bin/rails test:system

# Run sandbox end-to-end test (creates real sandbox, tests it, destroys it)
rake sandbox:test
```

**Note:** The E2E test takes 2-3 minutes as it creates a complete sandbox, starts a server, runs browser-based user journey tests, and cleans up.

See [docs/SANDBOX_TESTING.md](docs/SANDBOX_TESTING.md) for complete E2E testing documentation.

### Code Quality

```bash
# Linting
bundle exec rubocop

# Security scan
bundle exec brakeman
```

## Deployment

Deployment configuration should be set up in your parent application. Oroshi is a Rails engine gem and does not include deployment tooling.

For production deployment, configure your parent app with your preferred deployment strategy (Kamal, Capistrano, Heroku, etc.).

**Key requirements for production:**

- PostgreSQL 16 with 4-database setup (primary, queue, cache, cable)
- Background job processing (Solid Queue)
- Asset compilation (Tailwind CSS)
- Email delivery (configure Action Mailer)
- File storage (configure Active Storage)

## Architecture

### Engine Structure

Oroshi uses Rails engine architecture with namespace isolation:

- **Models**: All namespaced under `Oroshi::` (e.g., `Oroshi::Order`, `Oroshi::Buyer`)
- **Tables**: Prefixed with `oroshi_` (e.g., `oroshi_orders`, `oroshi_buyers`)
- **Routes**: Engine routes mounted in host application (see [Route Architecture](#route-architecture))
- **User Model**: Lives at application level (NOT namespaced) for flexibility

### Route Architecture

Oroshi uses the **single route file pattern** standard for Rails engines:

```
config/routes.rb                    # Engine routes (Oroshi::Engine.routes.draw)
test/dummy/config/routes.rb         # Test app routes (mounts engine)
sandbox/config/routes.rb            # Generated sandbox routes (mounts engine)
```

**Key Principle**: The engine's `config/routes.rb` uses `Oroshi::Engine.routes.draw` (NOT `Rails.application.routes.draw`). This ensures proper engine isolation and allows parent applications to control where the engine is mounted.

**Parent Application Setup:**

```ruby
# Parent app's config/routes.rb
Rails.application.routes.draw do
  devise_for :users                           # Devise routes at /users/*
  mount Oroshi::Engine, at: "/oroshi"         # Engine routes at /oroshi/*
  root "home#index"                           # Required for main_app.root_path
end
```

**Route Helpers:**

| Context | Engine Routes | Parent App Routes |
|---------|---------------|-------------------|
| Engine views/controllers | `oroshi_orders_path` | `main_app.root_path` |
| Parent app views/controllers | `oroshi.orders_path` | `root_path` |

**Critical Requirements:**
1. Parent apps MUST provide Devise routes (`devise_for :users`)
2. Parent apps MUST define a root route if engine uses `main_app.root_path`
3. Engine routes use `Oroshi::Engine.routes.draw`, never `Rails.application.routes.draw`

See [Engine Isolation & Routing](#engine-isolation--routing) in CLAUDE.md for detailed patterns.

### Multi-Database Architecture

Four PostgreSQL databases for separation of concerns:

1. **Primary** - Main application data (44 models)
2. **Queue** - Solid Queue background jobs
3. **Cache** - Solid Cache entries
4. **Cable** - Solid Cable WebSocket messages

### Background Jobs

Five Solid Queue jobs handle async operations:

- `Oroshi::MailerJob` - Email delivery (recurring every 10 minutes)
- `Oroshi::InvoiceJob` - PDF invoice generation
- `Oroshi::InvoicePreviewJob` - Invoice previews
- `Oroshi::OrderDocumentJob` - Order document PDFs
- `Oroshi::SupplyCheckJob` - Supply verification PDFs

### Frontend Styling

- **Bootstrap 5**: Primary UI framework
- **Custom Theme**: Oroshi brand colors defined in `app/assets/stylesheets/funabiki.scss`
- **Component Standards**: See [docs/BOOTSTRAP_COMPONENTS.md](docs/BOOTSTRAP_COMPONENTS.md)

**IMPORTANT**: All styling must use Bootstrap 5 utility classes or application stylesheets. Inline styles (`style="..."`) are **strictly prohibited**.

Button examples:

```erb
<!-- Primary action -->
<%= button_tag "Submit", class: "btn btn-primary" %>

<!-- Secondary action -->
<%= link_to "Back", previous_path, class: "btn btn-secondary" %>

<!-- Less prominent action -->
<%= link_to "Skip", skip_path, class: "btn btn-outline-secondary" %>
```

## Documentation

### Main Documentation

- [README.md](README.md) - This file
- [docs/archives/](docs/archives/) - Archived documentation and research

### Technical Guides

- [docs/TURBO.md](docs/TURBO.md) - Hotwire Turbo patterns
- [docs/STIMULUS.md](docs/STIMULUS.md) - Stimulus controller patterns
- [docs/ACTION_CABLE.md](docs/ACTION_CABLE.md) - WebSocket implementation
- [docs/BOOTSTRAP_COMPONENTS.md](docs/BOOTSTRAP_COMPONENTS.md) - Bootstrap component standards
- [docs/SANDBOX_TESTING.md](docs/SANDBOX_TESTING.md) - End-to-end sandbox testing

## Generators

### Install Generator

Sets up Oroshi in your Rails application.

```bash
rails generate oroshi:install [options]

Options:
  --skip-migrations    Skip copying migrations
  --skip-devise        Skip Devise setup
  --skip-user-model    Skip User model generation
```

See [Installation Details](#installation-details) section for what the generator creates.

## Browser Requirements

Oroshi requires modern browsers supporting:

- WebP images
- Web push notifications
- Import maps
- CSS nesting
- CSS `:has()` selector

## Version

**Current Version**: 1.0.0

See [GEM_CONVERSION_COMPLETE.md](GEM_CONVERSION_COMPLETE.md) for complete version history and conversion details.

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests (TDD approach)
4. Implement feature
5. Run test suite (`bin/rails test`)
6. Run linter (`bundle exec rubocop`)
7. Commit changes (`git commit -m 'Add amazing feature'`)
8. Push to branch (`git push origin feature/amazing-feature`)
9. Open Pull Request

## License

Copyright © 2026 MOAB Co., Ltd. All rights reserved.

## Support

- **Repository**: https://github.com/cmbaldwin/oroshi
- **Issues**: https://github.com/cmbaldwin/oroshi/issues
- **Documentation**: See `docs/` directory

## Acknowledgments

Built with ❤️ using Ruby on Rails 8.1.1 and modern web technologies.

Special thanks to the Rails community and the creators of Solid Queue, Solid Cache, and Solid Cable.

Conversion to Rails engine inspired by [Spree](https://spreecommerce.org/) and [Solidus](https://solidus.io/).

---

**Made in Japan** 🇯🇵 | **Powered by Rails** 🚂
