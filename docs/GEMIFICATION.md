# Oroshi Gemification Progress

This document tracks the progress of converting Oroshi from a standalone Rails application into a reusable Rails engine gem.

## Overview

The goal is to create an opinionated, production-ready Rails engine gem that:
- Works out-of-the-box with minimal configuration
- Includes authentication (Devise)
- Provides dead-simple deployment (2-3 commands)
- Includes a full-featured sandbox application

## Architecture

### Gem Structure
```
oroshi/
├── lib/oroshi/
│   ├── engine.rb          # Rails::Engine (loads Solid gems first!)
│   ├── configuration.rb   # Configuration DSL
│   └── version.rb         # Version (1.0.0)
├── app/                   # Engine application code
│   ├── models/oroshi/     # 38 namespaced models
│   ├── controllers/oroshi/# 37 namespaced controllers
│   ├── views/oroshi/      # All views
│   ├── jobs/oroshi/       # Background jobs
│   └── assets/            # CSS, JS, images, fonts
├── config/
│   ├── routes_oroshi_engine.rb  # Engine routes (170+ lines)
│   └── locales/           # Japanese i18n files
├── db/migrate/            # All migrations
└── test/                  # Test suite
```

### Critical Implementation Details

#### 1. Solid Gems Loading Order
**CRITICAL**: Solid gems MUST be loaded first in `lib/oroshi/engine.rb`:
```ruby
require "solid_queue"
require "solid_cache"
require "solid_cable"

module Oroshi
  class Engine < ::Rails::Engine
    # ...
  end
end
```

#### 2. Namespace Isolation
- All models: `Oroshi::Order`, `Oroshi::Buyer`, etc.
- All controllers: `Oroshi::DashboardController`, `Oroshi::OrdersController`, etc.
- All tables: `oroshi_orders`, `oroshi_buyers`, etc.
- Engine uses `isolate_namespace Oroshi`

#### 3. Multi-Database Setup
Four PostgreSQL databases:
- `oroshi_production` - Main application data
- `oroshi_production_queue` - Solid Queue jobs
- `oroshi_production_cache` - Solid Cache
- `oroshi_production_cable` - Solid Cable messages

## Implementation Phases

### ✅ Phase 0: Foundation & Gem Structure (COMPLETE)
- Created `oroshi.gemspec` with all dependencies
- Built `lib/oroshi/engine.rb` with critical Solid gems loading
- Implemented `lib/oroshi/configuration.rb` DSL
- Added `lib/oroshi/version.rb` (v1.0.0)
- Created MIT-LICENSE
- Set up test infrastructure (test/dummy/)
- Created foundation tests

**Status**: Complete - gem skeleton established

### ✅ Phase 1: Core Models Extraction (COMPLETE)
- All 38 models already in correct location: `app/models/oroshi/`
- All tables properly prefixed: `oroshi_*`
- Models work with engine structure
- Concerns properly organized

**Status**: Complete - models ready for engine

### 🚧 Phase 2: Controllers & Routes (IN PROGRESS)
- All 37 controllers already namespaced: `app/controllers/oroshi/`
- Created `config/routes_oroshi_engine.rb` with 170+ lines of routes
- Controllers inherit from ApplicationController (host app)
- Controller concerns in place

**Current Status**: Routes extracted, ready for engine mounting

**Next Steps**:
- Test route mounting in host app
- Verify controller tests pass
- Document route helpers for host apps

### ⏳ Phase 3: Views, Assets & Helpers (PENDING)
- Extract all view templates
- Move assets (CSS, JS, images, fonts - 14MB Japanese fonts)
- Extract helper modules
- Configure asset pipeline
- Set up i18n

### ⏳ Phase 4: Background Jobs (PENDING)
- Extract 5 Solid Queue job classes
- Configure recurring tasks
- Set up queue database

### ⏳ Phase 5: PDF Generation (PENDING)
- Extract Prawn-based printables library
- Configure Japanese font paths
- Verify PDF generation

### ⏳ Phase 6: Authentication (PENDING)
- Configure Devise in engine
- Extract User model
- Set up Devise views and controllers

### ⏳ Phase 7: Sandbox Application (PENDING)
- Create full demo app
- Add comprehensive seed data
- Document 3-command setup

### ⏳ Phase 8: Simple Deployment (PENDING)
- Create deployment generator
- Package Kamal configuration
- Implement 2-command deploy

## Usage (Once Complete)

### Installation
```bash
# Create new Rails app
rails new my_oroshi_app --database=postgresql

# Add gem
echo 'gem "oroshi"' >> Gemfile
bundle install

# Install
rails generate oroshi:install

# Setup and run
bin/rails db:setup
bin/rails server
```

### Deployment
```bash
rails generate oroshi:deployment \
  --domain=your-domain.com \
  --host=1.2.3.4

export KAMAL_HOST=1.2.3.4
export KAMAL_DOMAIN=your-domain.com
kamal setup    # First time
kamal deploy   # Subsequent deploys
```

## Testing Approach

- **TDD**: Tests written BEFORE implementation
- **Test Framework**: Test::Unit/Minitest (no RSpec)
- **Factories**: FactoryBot
- **Coverage**: 539+ examples expected

## Key Files

### Gem Core
- `oroshi.gemspec` - Gem specification
- `lib/oroshi/engine.rb` - Engine loader
- `lib/oroshi/configuration.rb` - Config DSL
- `lib/oroshi/version.rb` - Version management

### Application Code
- `app/models/oroshi/` - 38 models
- `app/controllers/oroshi/` - 37 controllers
- `config/routes_oroshi_engine.rb` - Engine routes

### Infrastructure
- `test/dummy/` - Minimal test app
- `MIT-LICENSE` - License file

## Branch Information

**Current Branch**: `gem-conversion`
**Base Branch**: `master`

## References

- [Rails Engines Guide](https://guides.rubyonrails.org/engines.html)
- Inspired by successful Rails engines (Solidus, Spree, Refinery)
- Full plan: `.claude/plans/sparkling-roaming-cherny.md`
