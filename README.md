# Oroshi - Wholesale Order Management System

A comprehensive wholesale order management system built with Ruby on Rails 8.1.1.

## Features

- **Order Management**: Complete order lifecycle from creation to fulfillment
- **Supply Tracking**: Multi-user supply entry and verification
- **Document Generation**: Automated invoices, packing lists, and reports (PDF)
- **Real-time Updates**: Turbo Streams with Solid Cable for live order updates
- **Background Jobs**: Solid Queue for email delivery and async processing
- **Customer Management**: Account management with delivery address tracking

## Tech Stack

- **Ruby** 4.0.0
- **Rails** 8.1.1
- **Database**: PostgreSQL 16 (4-database architecture)
- **Testing**: Minitest + Capybara (TDD approach)
- **Background Jobs**: Solid Queue
- **Real-time**: Solid Cable (WebSockets via PostgreSQL)
- **Caching**: Solid Cache
- **Frontend**: Hotwire (Turbo + Stimulus) + Bootstrap 5
- **Assets**: Propshaft + Importmap (no Node.js required)
- **Deployment**: Kamal 2 + Docker on Hetzner

## Getting Started

### Prerequisites

- Ruby 4.0.0
- PostgreSQL 16
- Docker (for deployment)

### Installation

```bash
# Clone the repository
git clone https://github.com/cmbaldwin/oroshi.git
cd oroshi

# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Initialize Solid gems schemas
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable

# Start the development server
bin/dev
```

### Running Tests

```bash
# Run full test suite
bin/rails test

# Run system tests
bin/rails test:system

# Run specific test file
bin/rails test test/models/product_test.rb
```

## Development

This project uses:

- **TDD**: Write tests first, then implementation
- **Minitest**: Rails default test framework
- **Capybara**: E2E system tests
- **Rubocop**: Code style enforcement

## Deployment

Deployed via Kamal 2 to Hetzner dedicated server.

See [CLAUDE.md](CLAUDE.md) for complete production deployment guide.

## Documentation

- [specs/PROJECT_OVERVIEW.md](specs/PROJECT_OVERVIEW.md) - Project overview and architecture
- [docs/TURBO.md](docs/TURBO.md) - Hotwire Turbo patterns
- [docs/STIMULUS.md](docs/STIMULUS.md) - Stimulus controller patterns
- [docs/ACTION_CABLE.md](docs/ACTION_CABLE.md) - WebSocket implementation

## License

Copyright © 2026 MOAB Co., Ltd. All rights reserved.
