# Comprehensive Site Documentation Plan

**Date:** 2026-02-18
**Branch:** `claude/comprehensive-site-documentation-p9YON`
**Goal:** Create rich, bilingual (Japanese/English) documentation with screenshots, workflow diagrams, and cross-references covering the entire Oroshi wholesale order management system.

---

## Problem Statement

Oroshi has 13,600+ lines of developer-facing documentation but **zero end-user documentation**. There are:
- No screenshots of the actual UI
- No workflow guides for operators
- No bilingual user guides (existing docs are English-only developer docs)
- No documentation testing infrastructure
- No cross-reference system linking features to code

An operator or new team member has no way to learn the system except by using it. This plan creates a comprehensive, tested, easy-to-maintain documentation suite.

---

## Architecture Decisions

### Documentation Format: In-App Guide Pages (Rails Views)

Rather than static markdown files that go stale, documentation will be **live Rails views** served from a `Oroshi::DocumentationController`. This gives us:

- **Bilingual support via i18n** — `t()` helpers for Japanese/English switching
- **Live screenshots** — System tests capture screenshots that are served as assets
- **Cross-references** — Link directly to related app pages with `*_path` helpers
- **Testable** — Controller tests verify pages render; i18n tests verify translations exist
- **Searchable** — Built-in search across all documentation pages
- **Maintainable** — When UI changes, screenshot tests fail, prompting updates

### Screenshot Strategy: Automated Capture via System Tests

- System tests using Capybara + headless Chrome capture screenshots during test runs
- Screenshots stored in `app/assets/images/docs/` organized by feature
- A rake task `docs:screenshots` runs the screenshot suite and updates images
- Screenshots are committed to the repo (they change infrequently)
- When the UI changes, failing screenshot tests signal that docs need updating

### Workflow Diagrams: Mermaid.js

- Rendered client-side using Mermaid.js (already importmap-compatible)
- Written inline in view templates
- Bilingual labels via i18n keys
- No external diagram tools needed

### File Organization

```
app/
  controllers/oroshi/
    documentation_controller.rb          # Serves all doc pages
  views/oroshi/documentation/
    index.html.erb                       # Documentation home / table of contents
    _sidebar.html.erb                    # Navigation sidebar partial
    _breadcrumbs.html.erb                # Breadcrumb navigation partial
    getting_started/
      index.html.erb                     # Getting started overview
      _first_login.html.erb              # First login walkthrough
      _navigation.html.erb               # Site navigation guide
      _onboarding.html.erb               # Onboarding checklist guide
    orders/
      index.html.erb                     # Orders overview
      _creating_orders.html.erb          # 1-2 click order creation
      _order_templates.html.erb          # Template system
      _order_lifecycle.html.erb          # Estimate → confirmed → shipped
      _bundling_orders.html.erb          # Bundling for shared shipping
      _searching_orders.html.erb         # Search & calendar
      _dashboard_tabs.html.erb           # 6 dashboard tabs overview
    supply_chain/
      index.html.erb                     # Supply chain overview
      _supply_intake.html.erb            # Daily supply entry
      _suppliers.html.erb                # Supplier management
      _supply_types.html.erb             # Supply types & variations
      _supply_check_sheets.html.erb      # PDF check sheet generation
    production/
      index.html.erb                     # Production overview
      _production_zones.html.erb         # Zone configuration
      _production_requests.html.erb      # Request workflow
      _factory_floor.html.erb            # Factory floor schedule views
    shipping/
      index.html.erb                     # Shipping overview
      _shipping_methods.html.erb         # Method configuration
      _receptacles.html.erb              # Container management
      _shipping_dashboard.html.erb       # Shipping chart/list/slips
    financials/
      index.html.erb                     # Financial overview
      _revenue_tracking.html.erb         # Revenue dashboard
      _profit_calculation.html.erb       # How costs → profit works
      _payment_receipts.html.erb         # Payment receipt workflows
      _invoices.html.erb                 # Supplier invoice management
      _materials_costs.html.erb          # Material cost configuration
    admin/
      index.html.erb                     # Admin overview
      _company_setup.html.erb            # Company information
      _buyer_management.html.erb         # Buyer configuration
      _product_management.html.erb       # Product & variation setup
      _user_management.html.erb          # User roles & access

config/locales/
  documentation.ja.yml                   # All Japanese documentation text
  documentation.en.yml                   # All English documentation text

test/
  controllers/oroshi/
    documentation_controller_test.rb     # Page rendering tests
  system/oroshi/
    documentation_screenshots_test.rb    # Screenshot capture tests
  integration/oroshi/
    documentation_i18n_test.rb           # Translation completeness tests
    documentation_links_test.rb          # Cross-reference validation

lib/tasks/
  docs.rake                             # docs:screenshots, docs:verify tasks

app/assets/images/docs/                  # Auto-captured screenshots
  getting_started/
  orders/
  supply_chain/
  production/
  shipping/
  financials/
  admin/
```

---

## Implementation Stages

### Stage 1: Documentation Infrastructure

**Objective:** Build the scaffolding that all documentation pages will use.

**Tasks:**

1. **Create `DocumentationController`**
   - Actions: `index`, `show` (renders section/page combos)
   - Authentication: accessible to all logged-in users
   - Layout: dedicated documentation layout with sidebar + breadcrumbs
   - Locale switching: respects `I18n.locale` parameter

2. **Add documentation routes**
   ```ruby
   # In config/routes.rb (Oroshi::Engine.routes.draw)
   resources :documentation, only: [:index] do
     collection do
       get ':section', action: :section, as: :section
       get ':section/:page', action: :page, as: :page
     end
   end
   ```

3. **Create documentation layout**
   - Sidebar with collapsible section navigation
   - Breadcrumb trail (Documentation > Orders > Creating Orders)
   - Language toggle (日本語 / English) that preserves current page
   - Search bar (client-side full-text search via Stimulus)
   - "Edit this page" link for maintainers
   - Responsive: works on desktop and tablet

4. **Set up Mermaid.js for workflow diagrams**
   - Pin via importmap: `bin/importmap pin mermaid`
   - Create Stimulus controller `documentation-diagram` to initialize Mermaid
   - Support bilingual labels via data attributes

5. **Create screenshot capture infrastructure**
   - System test base class `DocumentationScreenshotTest`
   - Helper methods: `capture_screenshot(name, &block)` — navigates, waits for load, captures
   - Screenshot naming convention: `docs/{section}/{page_name}.png`
   - Rake task `docs:screenshots` runs just the screenshot test suite
   - Screenshots saved to `app/assets/images/docs/`

6. **Create locale file skeleton**
   - `documentation.ja.yml` with full key structure (Japanese text)
   - `documentation.en.yml` with full key structure (English text)
   - Both files have identical key hierarchies

7. **Create documentation test infrastructure**
   - Controller test: every section/page renders 200
   - i18n test: every key in `documentation.ja.yml` exists in `documentation.en.yml` and vice versa
   - Link test: every cross-reference path resolves to a valid route
   - Screenshot test: every referenced image file exists

**Files created/modified:**
- `app/controllers/oroshi/documentation_controller.rb` (new)
- `app/views/oroshi/documentation/index.html.erb` (new)
- `app/views/oroshi/documentation/_sidebar.html.erb` (new)
- `app/views/oroshi/documentation/_breadcrumbs.html.erb` (new)
- `app/views/layouts/oroshi/documentation.html.erb` (new)
- `app/javascript/controllers/oroshi/documentation_search_controller.js` (new)
- `app/javascript/controllers/oroshi/documentation_diagram_controller.js` (new)
- `config/routes.rb` (modified — add documentation routes)
- `config/locales/documentation.ja.yml` (new)
- `config/locales/documentation.en.yml` (new)
- `test/controllers/oroshi/documentation_controller_test.rb` (new)
- `test/system/oroshi/documentation_screenshots_test.rb` (new)
- `test/integration/oroshi/documentation_i18n_test.rb` (new)
- `lib/tasks/docs.rake` (new)

---

### Stage 2: Getting Started & Onboarding Documentation

**Objective:** Guide new users from first login through complete system setup.

**Pages:**

1. **Getting Started Index** — Overview of Oroshi, what it does, who it's for
2. **First Login** — What you see after logging in, navigation orientation
   - Screenshot: dashboard home page
   - Screenshot: navigation bar with labels
3. **Navigation Guide** — Sidebar sections, date navigation, quick actions
   - Screenshot: main navigation annotated
   - Screenshot: date picker / calendar
4. **Onboarding Checklist** — 13-step setup wizard walkthrough
   - Screenshot: onboarding checklist dropdown
   - Screenshot: each onboarding step page
   - Workflow diagram: onboarding completion flow

**Cross-references:** Links to each admin setup section for detailed configuration

**i18n keys:** ~80 keys (titles, paragraphs, captions, alt text)

---

### Stage 3: Orders Documentation (Core Workflow)

**Objective:** Document the primary workflow — the 1-2 click order system that is the heart of Oroshi.

**Pages:**

1. **Orders Overview** — What orders are, the order lifecycle, dashboard layout
   - Workflow diagram: Order lifecycle (estimate → confirmed → shipped → paid)

2. **Creating Orders (1-2 Click Flow)** — Step-by-step with screenshots
   - Screenshot: empty order form
   - Screenshot: buyer selected → shipping methods filtered
   - Screenshot: product selected → variations shown
   - Screenshot: quantities entered → costs auto-calculated
   - Screenshot: completed order in dashboard
   - Workflow diagram: Cascading form field dependencies
   - Cross-reference: Buyer management, Product management, Shipping methods

3. **Order Templates** — How to create, use, and manage templates
   - Screenshot: template creation toggle
   - Screenshot: template in dashboard
   - Screenshot: creating order from template
   - Cross-reference: Creating Orders

4. **Order Lifecycle** — Status transitions and what triggers them
   - Workflow diagram: Status state machine
   - Screenshot: order status indicators
   - Cross-reference: Production requests, Payment receipts

5. **Bundling Orders** — Combining orders for shared shipping
   - Screenshot: bundle toggle and order selector
   - Screenshot: bundled orders in dashboard (shipping cost = ¥0)
   - Cross-reference: Shipping costs, Revenue tracking

6. **Searching Orders** — Search interface, calendar view, filters
   - Screenshot: search form
   - Screenshot: calendar view
   - Screenshot: search results

7. **Dashboard Tabs** — Overview of all 6 dashboard views
   - Screenshot: each tab (orders, templates, production, shipping, sales, revenue)
   - Cross-reference: Production, Shipping, Revenue sections

**i18n keys:** ~150 keys

---

### Stage 4: Supply Chain Documentation

**Objective:** Document supply intake, supplier management, and the supply type hierarchy.

**Pages:**

1. **Supply Chain Overview** — How suppliers → supply types → products connect
   - Workflow diagram: Supply chain data model
   - Cross-reference: Product management

2. **Supply Intake** — Daily supply entry workflow
   - Screenshot: supply date entry page
   - Screenshot: supply entry form (multi-entry)
   - Screenshot: supply list for a date
   - Workflow diagram: Supply intake → inventory → production

3. **Supplier Management** — Organizations, suppliers, reception times
   - Screenshot: supplier organization list
   - Screenshot: supplier detail with address
   - Screenshot: reception time configuration
   - Cross-reference: Invoice management

4. **Supply Types & Variations** — Categorization hierarchy
   - Screenshot: supply type list
   - Screenshot: variation detail with cost info
   - Workflow diagram: SupplyType → Variation → Supplier mapping
   - Cross-reference: Product variations (how they link)

5. **Supply Check Sheets** — PDF generation workflow
   - Screenshot: check sheet generation UI
   - Screenshot: sample PDF output
   - Cross-reference: Supply intake

**i18n keys:** ~100 keys

---

### Stage 5: Production & Shipping Documentation

**Objective:** Document how orders become factory floor tasks and shipping logistics.

**Pages:**

1. **Production Overview** — How orders flow to the factory floor
   - Workflow diagram: Order → ProductionRequest → Fulfillment → Inventory update

2. **Production Zones** — Configuring factory floor areas
   - Screenshot: production zone list
   - Screenshot: zone configuration
   - Cross-reference: Product variations (zone assignment)

3. **Production Requests** — How requests are created and tracked
   - Screenshot: production request list
   - Screenshot: fulfillment progress indicators
   - Workflow diagram: Request lifecycle

4. **Factory Floor Schedule** — The 3 production dashboard views
   - Screenshot: manufacture date view (3-day window)
   - Screenshot: shipping date view
   - Screenshot: sort-by-zone view
   - Cross-reference: Order dashboard production tab

5. **Shipping Overview** — Shipping configuration and logistics
   - Screenshot: shipping organization list
   - Screenshot: shipping method detail (costs, departure times)
   - Cross-reference: Order creation (shipping method selection)

6. **Receptacles** — Container types and packing calculations
   - Screenshot: receptacle list with dimensions
   - Screenshot: per-box estimate calculation
   - Cross-reference: Order creation (quantity linking)

7. **Shipping Dashboard** — Chart, list, and slip views
   - Screenshot: shipping chart (grouped by carrier)
   - Screenshot: shipping list (by recipient)
   - Screenshot: shipping slips (individual labels)
   - Cross-reference: Order bundling

**i18n keys:** ~120 keys

---

### Stage 6: Financial Documentation

**Objective:** Document revenue tracking, profit calculation, payments, and invoices.

**Pages:**

1. **Financial Overview** — How money flows through Oroshi
   - Workflow diagram: Order revenue → Expenses → Profit → Payment receipt

2. **Revenue Tracking** — The revenue dashboard tab
   - Screenshot: revenue dashboard for a date
   - Screenshot: per-product revenue breakdown
   - Screenshot: daily expenses summary
   - Cross-reference: Order dashboard revenue tab

3. **Profit Calculation** — Detailed cost breakdown explanation
   - Workflow diagram: All cost components → final profit
   - Tables showing: shipping cost formula, materials cost formula, revenue formula
   - Cross-reference: Materials costs, Shipping methods, Buyer commissions

4. **Payment Receipts** — Quick entry and single entry workflows
   - Screenshot: quick entry page (buyers with outstanding orders)
   - Screenshot: single entry form
   - Screenshot: payment receipt detail
   - Screenshot: adjustment line items
   - Workflow diagram: Order → PaymentReceipt → Deposit tracking
   - Cross-reference: Order lifecycle (payment association)

5. **Invoices** — Supplier invoice management
   - Screenshot: invoice list
   - Screenshot: invoice creation (date grouping)
   - Screenshot: invoice PDF (standard and simple layouts)
   - Screenshot: email sending interface
   - Cross-reference: Supply dates, Supplier management

6. **Materials & Costs** — Material configuration and cost modeling
   - Screenshot: material list
   - Screenshot: material form (per-item, per-box, per-freight, per-supply-unit)
   - Screenshot: product material cost breakdown
   - Workflow diagram: Material cost calculation for each billing type
   - Cross-reference: Product management, Profit calculation

**i18n keys:** ~130 keys

---

### Stage 7: Admin & Setup Documentation

**Objective:** Document system configuration for administrators.

**Pages:**

1. **Admin Overview** — What administrators can configure
   - Cross-reference: Onboarding checklist (setup wizard)

2. **Company Setup** — Company information, addresses, settings
   - Screenshot: company info form
   - Screenshot: address management

3. **Buyer Management** — Creating and configuring buyers
   - Screenshot: buyer list (color-coded)
   - Screenshot: buyer form (costs, commission, entity type)
   - Screenshot: buyer shipping method associations
   - Cross-reference: Order creation (buyer selection), Revenue tracking

4. **Product Management** — Products, variations, and packaging
   - Screenshot: product list
   - Screenshot: product form with material associations
   - Screenshot: product variation form (packaging, shelf life, dimensions)
   - Screenshot: product cost breakdown
   - Workflow diagram: Product → Variations → Materials → Cost
   - Cross-reference: Order creation, Supply types

5. **User Management** — Roles, access levels, Devise integration
   - Screenshot: user list
   - Screenshot: user role configuration
   - Cross-reference: Getting started

**i18n keys:** ~100 keys

---

### Stage 8: Cross-References, Search, and Polish

**Objective:** Wire everything together with cross-references, search, and final polish.

**Tasks:**

1. **Build cross-reference index**
   - Each page declares its cross-references in a data structure
   - Sidebar shows "Related Pages" section
   - Bottom of each page shows "See Also" links
   - Helper: `doc_link_to(section, page)` generates proper bilingual links

2. **Implement client-side search**
   - Stimulus controller indexes all documentation content on page load
   - Search input in sidebar with instant results
   - Results link to specific pages with highlighted matches
   - Search works across both languages

3. **Add contextual help links from main app**
   - Each major feature page gets a small "?" help icon
   - Links to the relevant documentation section
   - Helper: `documentation_help_link(section, page)` in application helper

4. **Print-friendly styles**
   - CSS `@media print` styles for documentation pages
   - Clean layout without sidebar/navigation
   - Screenshots render at appropriate size

5. **Documentation home page**
   - Visual grid of all sections with icons
   - Quick links to most common tasks
   - "What's New" section for recent documentation updates

6. **Final testing pass**
   - Run all documentation tests (controller, i18n, links, screenshots)
   - Verify all cross-references resolve
   - Verify both languages are complete
   - Verify all screenshots are current
   - Run `docs:verify` rake task

**Files created/modified:**
- `app/helpers/oroshi/documentation_helper.rb` (new)
- `app/javascript/controllers/oroshi/documentation_search_controller.js` (enhanced)
- `app/assets/stylesheets/oroshi/documentation.css` (new)
- All documentation view templates (enhanced with cross-references)
- `lib/tasks/docs.rake` (enhanced with `docs:verify`)

---

## Testing Strategy

### Test Categories

| Test Type | What It Verifies | Run Frequency |
|-----------|-----------------|---------------|
| Controller tests | Every page renders 200 in both locales | Every CI run |
| i18n completeness | Every JA key has EN equivalent and vice versa | Every CI run |
| Cross-reference validation | Every `doc_link_to` resolves to valid route | Every CI run |
| Screenshot capture | Screenshots exist for all referenced images | On demand (`docs:screenshots`) |
| Screenshot freshness | UI changes trigger test failures for affected screenshots | Every CI run (optional) |

### Test Commands

```bash
# Run all documentation tests
bin/rails test test/controllers/oroshi/documentation_controller_test.rb \
               test/integration/oroshi/documentation_i18n_test.rb

# Capture/update screenshots
bin/rails docs:screenshots

# Verify documentation completeness
bin/rails docs:verify
```

---

## Estimated Scope

| Stage | New Files | i18n Keys | Screenshots |
|-------|-----------|-----------|-------------|
| 1. Infrastructure | ~14 | ~30 (nav/chrome) | 0 |
| 2. Getting Started | ~4 | ~80 | ~8 |
| 3. Orders | ~7 | ~150 | ~16 |
| 4. Supply Chain | ~5 | ~100 | ~12 |
| 5. Production & Shipping | ~7 | ~120 | ~14 |
| 6. Financials | ~6 | ~130 | ~14 |
| 7. Admin & Setup | ~5 | ~100 | ~10 |
| 8. Cross-refs & Search | ~3 | ~20 | 0 |
| **Total** | **~51** | **~730** | **~74** |

---

## Maintenance Plan

### When UI Changes
1. Run `bin/rails docs:screenshots` — failing screenshots indicate which docs need updates
2. Update the affected screenshot and any text describing the changed UI
3. Run `bin/rails docs:verify` to confirm completeness

### When Features Are Added
1. Add new documentation page(s) in the appropriate section
2. Add i18n keys in both `documentation.ja.yml` and `documentation.en.yml`
3. Add cross-references from related pages
4. Add screenshot capture test
5. Run full documentation test suite

### When Features Are Removed
1. Remove the documentation page
2. Remove associated i18n keys
3. Remove cross-references (link test will catch orphans)
4. Remove screenshot capture test and image files

---

## Implementation Order & Dependencies

```
Stage 1 (Infrastructure) ──── MUST be first, all others depend on it
    │
    ├── Stage 2 (Getting Started) ──── Can start immediately after Stage 1
    │
    ├── Stage 3 (Orders) ──── Can start immediately after Stage 1
    │       │                  (highest value — core workflow)
    │       │
    │       ├── Stage 5 (Production & Shipping) ──── Depends on Stage 3
    │       │                                         (references order dashboard)
    │       │
    │       └── Stage 6 (Financials) ──── Depends on Stage 3
    │                                      (references order costs)
    │
    ├── Stage 4 (Supply Chain) ──── Can start immediately after Stage 1
    │
    ├── Stage 7 (Admin & Setup) ──── Can start immediately after Stage 1
    │
    └── Stage 8 (Cross-refs & Search) ──── MUST be last
                                            (needs all content in place)
```

Stages 2, 3, 4, and 7 can be developed in parallel after Stage 1 is complete.
Stages 5 and 6 should follow Stage 3.
Stage 8 wraps everything up.
