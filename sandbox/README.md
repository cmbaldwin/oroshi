# Oroshi Sandbox Application

This is a demonstration application for the **Oroshi** Rails engine - a comprehensive wholesale order management system for Japanese food distribution businesses.

## What is This?

The Oroshi Sandbox is a fully-functional Rails application that demonstrates how to integrate the Oroshi engine into your own Rails project. It comes pre-configured with:

- **Complete authentication** via Devise
- **Demo users** (admin, VIP, regular user)
- **Sample master data** (suppliers, products, buyers, shipping methods)
- **Multi-database setup** for Solid Queue, Solid Cache, and Solid Cable
- **Japanese-first i18n** with all translations

## Prerequisites

- Ruby 4.0.0 (configured in `.ruby-version` from parent directory)
- PostgreSQL 16
- Bundler

## Quick Start (3 Commands)

```bash
# 1. Install dependencies
bundle install

# 2. Setup databases and seed data
bin/rails db:setup

# 3. Start the server
bin/rails server
```

Visit **http://localhost:3000** and sign in with:

- **Admin**: `admin@oroshi.local` / `password123`
- **VIP**: `vip@oroshi.local` / `password123`
- **Regular User**: `user@oroshi.local` / `password123`

## What's Included

### Demo Users

Three user accounts with different permission levels:

| Role    | Email                 | Password      | Access Level        |
| ------- | --------------------- | ------------- | ------------------- |
| Admin   | admin@oroshi.local    | password123   | Full system access  |
| VIP     | vip@oroshi.local      | password123   | Dashboard + orders  |
| Regular | user@oroshi.local     | password123   | Limited access      |

### Sample Master Data

The seed file creates a complete demo dataset:

- **Company**: 株式会社オロシサーモン (Oroshi Salmon Co.)
- **Supplier Organization**: 北海水産協同組合 (Hokkai Fisheries Cooperative)
- **Supplier**: 札幌サーモン株式会社 (Sapporo Salmon Co.)
- **Supply Type**: 鮭 (Salmon) with フィレカット (Fillet Cut) variation
- **Buyer**: 築地市場 (Tsukiji Market)
- **Product**: 鮭パック (Salmon Pack) - 1kg fillet variation
- **Shipping Receptacle**: 保冷箱M (Cold Box M)
- **Production Zone**: 北海道ゾーンA (Hokkaido Zone A)
- **Shipping Method**: 冷蔵便 (Refrigerated Delivery) via オロシエクスプレス (Oroshi Express)
- **Order Category**: 試験注文 (Test Order)

### Multi-Database Setup

The sandbox uses 4 PostgreSQL databases (following Oroshi's architecture):

1. **oroshi_sandbox_development** - Main application data
2. **oroshi_sandbox_development_queue** - Solid Queue background jobs
3. **oroshi_sandbox_development_cache** - Solid Cache entries
4. **oroshi_sandbox_development_cable** - Solid Cable WebSocket messages

All databases are created and migrated automatically when you run `bin/rails db:setup`.

## Configuration

### Environment Variables

The sandbox loads environment variables from `.env` (copy from parent directory's `.env.example`):

```bash
# Database
POSTGRES_USER=oroshi
POSTGRES_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432

# Oroshi settings
OROSHI_DOMAIN=localhost
```

### Oroshi Configuration

See [config/application.rb](config/application.rb:L13-L17) for Oroshi configuration:

```ruby
Oroshi.configure do |oroshi|
  oroshi.time_zone = "Asia/Tokyo"
  oroshi.locale = :ja
  oroshi.domain = ENV.fetch("OROSHI_DOMAIN", "localhost")
end
```

## Development

### Running Tests

```bash
bin/rails test
```

### Rails Console

```bash
bin/rails console
```

### Database Operations

```bash
# Reset and re-seed database
bin/rails db:reset

# Check migrations status
bin/rails db:migrate:status

# Access database console
bin/rails dbconsole
```

### Background Jobs (Solid Queue)

In development, Active Job uses the `:async` adapter (in-memory). For production-like behavior with Solid Queue:

```bash
# Start Solid Queue worker
bin/jobs
```

## Exploring Oroshi Features

After signing in, you can explore:

### Dashboard (VIP/Admin)

- **Home** - Overview and quick actions
- **Orders** - Create and manage orders
- **Supplies** - Track supplier deliveries
- **Products** - Product catalog management
- **Invoices** - Generate and send invoices (PDFs)

### Admin Features (Admin only)

- **Onboarding** - Interactive setup wizard for new deployments
- **Settings** - Company information and system configuration
- **Master Data** - Suppliers, buyers, shipping methods, etc.

### Key Features to Try

1. **Create an Order** - Navigate to Orders → New Order
2. **Supply Entry** - Track incoming supplies from suppliers
3. **Generate Invoices** - Create PDF invoices for suppliers
4. **Onboarding Flow** - View the interactive setup wizard (as admin)

## Project Structure

```
sandbox/
├── app/
│   ├── controllers/
│   │   └── application_controller.rb  # Base controller with auth
│   ├── models/
│   │   ├── application_record.rb
│   │   └── user.rb                    # User model (NOT namespaced)
│   └── views/
├── bin/
│   ├── rails
│   ├── rake
│   └── setup                          # Automated setup script
├── config/
│   ├── application.rb                 # Oroshi configuration
│   ├── database.yml                   # 4-database setup
│   ├── routes.rb                      # Mounts Oroshi engine
│   ├── storage.yml                    # Active Storage config
│   └── environments/
│       ├── development.rb
│       ├── production.rb              # Solid gems configuration
│       └── test.rb
├── db/
│   └── seeds.rb                       # Demo data
├── Gemfile                            # Points to local Oroshi gem
└── README.md                          # This file
```

## Key Architectural Patterns

### 1. User Model at Application Level

The `User` model lives at the **application level** (not in the Oroshi namespace), following Rails engine best practices. This allows:

- Host applications to customize user authentication
- Flexibility for different auth strategies
- Oroshi models to associate with `User` directly

### 2. Engine Mounting

The Oroshi engine is mounted at the root (`/`) in [config/routes.rb](config/routes.rb:L3):

```ruby
mount Oroshi::Engine, at: "/"
```

This makes Oroshi routes available as if they were part of the main application.

### 3. Solid Gems Integration

Production environment explicitly loads Solid gems **before** Rails configuration ([config/environments/production.rb](config/environments/production.rb:L4-L6)):

```ruby
require "solid_queue"
require "solid_cache"
require "solid_cable"
```

This ensures Railties register properly for multi-database connections.

## Deployment

The sandbox can be deployed to production using Kamal (just like the main Oroshi application).

For deployment instructions, see the main [Oroshi deployment documentation](../CLAUDE.md).

## Troubleshooting

### Database Connection Errors

Ensure PostgreSQL is running and environment variables are set:

```bash
# Check PostgreSQL status
pg_isready

# Verify environment variables
echo $POSTGRES_USER
echo $DB_HOST
```

### Asset Loading Issues

If assets aren't loading, precompile them:

```bash
bin/rails assets:precompile
```

### Solid Queue Not Starting

In development, jobs use the `:async` adapter. To test Solid Queue:

1. Update [config/environments/development.rb](config/environments/development.rb:L62) to use `:solid_queue`
2. Ensure queue database exists: `bin/rails db:create`
3. Load queue schema: `bin/rails db:schema:load:queue`
4. Start worker: `bin/jobs`

## Learn More

- **Main Oroshi Repository**: [github.com/cmbaldwin/oroshi](https://github.com/cmbaldwin/oroshi)
- **Oroshi Engine Documentation**: See parent directory's [README.md](../README.md)
- **Deployment Guide**: See [CLAUDE.md](../CLAUDE.md)

## License

This sandbox application demonstrates the Oroshi engine, which is available under the MIT License.

---

**Need help?** Open an issue at: https://github.com/cmbaldwin/oroshi/issues
