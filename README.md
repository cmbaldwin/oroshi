# Oroshi - Wholesale Order Management Rails Engine

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
- **Deployment**: Kamal 2 + Docker

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

See `sandbox/config/database.yml` for a complete example.

## Sandbox Application

A fully-functional demo application is included in the `sandbox/` directory:

```bash
cd sandbox
bundle install
bin/rails db:setup
bin/rails server
```

The sandbox demonstrates complete Oroshi integration with:

- **3 demo users** (admin, VIP, regular) - all password: `password123`
- **Complete master data** (suppliers, products, buyers, shipping methods)
- **Minimal configuration** (only 20 lines in application.rb)

See [sandbox/README.md](sandbox/README.md) for details.

## Demo Users (Sandbox)

The sandbox creates three demo accounts:

- **Admin**: `admin@oroshi.local` / `password123` - Full system access
- **VIP**: `vip@oroshi.local` / `password123` - Dashboard and orders
- **Regular**: `user@oroshi.local` / `password123` - Limited access

## Onboarding

New users are guided through a step-by-step onboarding wizard to set up:

1. **Company Information** - Business details and invoice settings
2. **Supply Chain** - Reception times, supplier organizations, suppliers, supply types
3. **Sales** - Buyers and products with variations
4. **Shipping** - Organizations, methods, receptacles, and order categories

The wizard can be skipped and resumed later via a persistent checklist sidebar.

## Development

### Running the Sandbox

```bash
cd sandbox
bin/rails server
```

### Running Tests

```bash
# Run full test suite (539 examples)
bin/rails test

# Run specific test file
bin/rails test test/models/oroshi/order_test.rb

# Run system tests
bin/rails test:system
```

### Code Quality

```bash
# Linting
bundle exec rubocop

# Security scan
bundle exec brakeman
```

## Deployment

Oroshi includes a deployment generator for automated Kamal setup:

```bash
# Generate deployment configuration
rails generate oroshi:deployment \
  --domain=oroshi.example.com \
  --host=192.168.1.100

# Configure secrets
cp .kamal/secrets-example .kamal/secrets
# Edit .kamal/secrets with your credentials

# Deploy to production
export KAMAL_HOST=192.168.1.100
export KAMAL_DOMAIN=oroshi.example.com
kamal setup   # First time only
kamal deploy  # All subsequent deployments
```

### What the Deployment Generator Creates

1. **Kamal configuration** (`config/deploy.yml`)
   - Web and worker containers
   - PostgreSQL with 4 databases
   - Automated backups with GCS sync
   - SSL via Cloudflare origin certificates

2. **Dockerfile** - Multi-stage production build
3. **Docker entrypoint** - Automatic database initialization
4. **Pre-build hook** - Quality gates (RuboCop, Brakeman, tests)
5. **Secrets template** - All required environment variables
6. **Database setup SQL** - Multi-database initialization

See [CLAUDE.md](CLAUDE.md) for comprehensive production deployment guide.

## Architecture

### Engine Structure

Oroshi uses Rails engine architecture with namespace isolation:

- **Models**: All namespaced under `Oroshi::` (e.g., `Oroshi::Order`, `Oroshi::Buyer`)
- **Tables**: Prefixed with `oroshi_` (e.g., `oroshi_orders`, `oroshi_buyers`)
- **Routes**: Mounted at "/" in host application
- **User Model**: Lives at application level (NOT namespaced) for flexibility

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
- [CLAUDE.md](CLAUDE.md) - Production deployment guide
- [GEM_CONVERSION_COMPLETE.md](GEM_CONVERSION_COMPLETE.md) - Complete conversion summary

### Phase Documentation
- [PHASE0_SUMMARY.md](PHASE0_SUMMARY.md) - Foundation & gem structure
- [PHASE1_SUMMARY.md](PHASE1_SUMMARY.md) - Core models
- [PHASE2_SUMMARY.md](PHASE2_SUMMARY.md) - Controllers & routes
- [PHASE3_SUMMARY.md](PHASE3_SUMMARY.md) - Views, assets & helpers
- [PHASE4_SUMMARY.md](PHASE4_SUMMARY.md) - Background jobs
- [PHASE5_SUMMARY.md](PHASE5_SUMMARY.md) - PDF generation
- [PHASE6_SUMMARY.md](PHASE6_SUMMARY.md) - Authentication
- [PHASE7_SUMMARY.md](PHASE7_SUMMARY.md) - Sandbox application
- [PHASE8_SUMMARY.md](PHASE8_SUMMARY.md) - Simple deployment

### Sandbox Documentation
- [sandbox/README.md](sandbox/README.md) - Integration example (400+ lines)

### Technical Guides
- [docs/TURBO.md](docs/TURBO.md) - Hotwire Turbo patterns
- [docs/STIMULUS.md](docs/STIMULUS.md) - Stimulus controller patterns
- [docs/ACTION_CABLE.md](docs/ACTION_CABLE.md) - WebSocket implementation
- [docs/BOOTSTRAP_COMPONENTS.md](docs/BOOTSTRAP_COMPONENTS.md) - Bootstrap component standards

## Generators

### Install Generator

```bash
rails generate oroshi:install [options]

Options:
  --skip-migrations    Skip copying migrations
  --skip-devise        Skip Devise setup
  --skip-user-model    Skip User model generation
```

### Deployment Generator

```bash
rails generate oroshi:deployment [options]

Options:
  --domain=DOMAIN        Application domain (e.g., oroshi.example.com)
  --host=HOST            SSH host/IP for deployment
  --registry=REGISTRY    Docker registry (default: docker.io)
  --skip-dockerfile      Skip Dockerfile generation
  --skip-secrets         Skip secrets template
```

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
