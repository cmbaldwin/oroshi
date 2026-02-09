# Oroshi Seeds

This directory contains optional seed data files for the Oroshi engine.

## Files

### `demo_data.rb`

Comprehensive demo data for sandbox environments and development.

**Usage:**

```bash
# From sandbox or parent application
DEMO_DATA=true bin/rails db:seed
```

**What it creates:**

- Company settings with realistic Japanese business information
- Supply chain data:
  - 3 supply reception times (morning, afternoon, evening)
  - 2 supplier organizations (Hokkaido, Aomori cooperatives)
  - 3 suppliers with invoice numbers and representatives
  - 3 supply types (salmon, tuna, scallop) with 4 variations
- Sales data:
  - 4 buyers (Tsukiji, Toyosu, Sapporo markets + direct restaurant)
  - 3 products with 4 variations
  - 3 production zones
- Shipping infrastructure:
  - 3 shipping receptacles (S/M/L cold boxes)
  - 2 shipping organizations
  - 3 shipping methods (cold/frozen cargo, direct delivery)
- Order management:
  - 4 order categories (regular, urgent, sample, test)
  - 2 order templates (weekly salmon, biweekly tuna)
  - ~50+ sample orders spanning past 2 weeks and next 7 days
- User onboarding:
  - Onboarding progress records for all users
  - Admin users marked as "skipped" (have demo data)
  - Non-admin users can see onboarding UI

**Notes:**

- All data uses `find_or_create_by` / `find_or_initialize_by` for idempotency
- Safe to run multiple times
- Only runs when `DEMO_DATA=true` environment variable is set
- Realistic Japanese business names and addresses
- Orders include past history and future scheduled deliveries

## Adding New Seed Files

1. Create a new file in this directory (e.g., `production_data.rb`)
2. Add environment guard at the top:
   ```ruby
   unless ENV["MY_SEED_FLAG"] == "true"
     puts "Skipping my seed data..."
     return
   end
   ```
3. Load it from `db/seeds.rb` or application-specific seeds

## Onboarding Examples

The legacy `onboarding_examples.rb` file contains minimal example data for onboarding flow testing. This is now superseded by `demo_data.rb` which includes all onboarding data plus comprehensive order/business data.

To use onboarding examples only:

```bash
# Edit demo_data.rb to set ENV guard to false or
# Copy specific sections needed
```
