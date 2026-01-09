# Oroshi - Wholesale Order Management System

## Project Overview

Oroshi is a comprehensive wholesale order management system built with Ruby on Rails 8.1.1. The system manages the complete lifecycle of wholesale orders from customer ordering through fulfillment.

## Core Features

### Order Management
- Create and manage wholesale orders
- Track order status throughout fulfillment
- Support for multiple order types and workflows
- Real-time order updates via Turbo Streams

### Supply Management
- Track product supply levels
- Supply entry and verification
- Packing list generation
- Supply check reporting

### Customer Management
- Customer account management
- Delivery address management
- Order history and reporting
- Customer-specific pricing

### Product Management
- Product catalog with SKU tracking
- Category and classification management
- Pricing management
- Inventory tracking

### Document Generation
- Invoice generation (PDF)
- Packing lists (PDF)
- Supply check reports (PDF)
- Delivery documentation

### Background Processing
- Email delivery via Solid Queue
- Document generation jobs
- Data import/export processing
- Automated notifications

## Technical Architecture

### Database Design
- PostgreSQL 16 with 4 separate databases
- Primary database: Application data (41+ tables)
- Queue database: Solid Queue jobs
- Cache database: Solid Cache entries
- Cable database: Solid Cable WebSocket messages

### Real-time Features
- Turbo Streams for live updates
- Solid Cable for WebSocket connections
- Real-time order status updates
- Multi-user supply entry coordination

### Background Jobs
- Solid Queue replaces traditional Redis-based solutions
- 4 queue processes: Supervisor, Dispatcher, Worker, Scheduler
- Recurring tasks (email checks, data cleanup)
- Async document generation

### Frontend Stack
- Hotwire (Turbo + Stimulus)
- Bootstrap 5 for UI components
- Importmap for JavaScript management (no Node.js)
- Dartsass Rails for SCSS compilation

### Deployment
- Kamal 2 for zero-downtime deployments
- Docker containers on Hetzner dedicated server
- AWS ECR for Docker registry
- Cloudflare for SSL and CDN

## Testing Strategy

### Minitest Framework
- Unit tests for models and business logic
- Controller tests for request/response handling
- Integration tests for multi-step workflows
- System tests (Capybara) for E2E user flows

### Test Coverage Goals
- 85%+ code coverage for new features
- Comprehensive system tests for critical workflows
- Test-driven development (TDD) approach
- Focus on business logic and edge cases

## Development Principles

1. **Keep Files Small**: Use concerns, helpers, and partials to DRY up code
2. **Intuitive Structure**: Organize code into logical subdirectories
3. **Clear Documentation**: Comment WHY not WHAT, update docs with code
4. **TDD Approach**: Write tests first, implement second
5. **Rails Conventions**: Follow Rails best practices and naming
6. **Performance**: Optimize queries, use caching, eager load associations

## Reference Documentation

See the `docs/` directory for detailed technical documentation:
- [TURBO.md](../docs/TURBO.md) - Hotwire Turbo usage patterns
- [STIMULUS.md](../docs/STIMULUS.md) - Stimulus controller patterns
- [ACTION_CABLE.md](../docs/ACTION_CABLE.md) - WebSocket implementation
- [DEPLOYMENT_MIGRATION.md](../docs/DEPLOYMENT_MIGRATION.md) - Kamal deployment guide
- [CREDENTIAL_MANAGEMENT_PLAN.md](../docs/CREDENTIAL_MANAGEMENT_PLAN.md) - Secrets management

See [CLAUDE.md](../CLAUDE.md) for production deployment guide.
