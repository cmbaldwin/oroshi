# PRD: User Onboarding & Dashboard Setup

## Introduction

Create a step-by-step onboarding wizard for new Oroshi users that guides them through setting up the minimum required data to track raw material costs and create wholesale orders. The onboarding ensures users don't encounter errors when accessing a dashboard with no data, and provides a persistent checklist sidebar for users who skip steps.

Additionally, replace the logo with stylized "OROSHI" text using a free elegant font.

## Goals

- Allow new users to access the dashboard without errors when no data exists
- Guide users through two-phase setup: Supply Chain → Sales/Orders
- Provide fullscreen step-by-step wizard experience
- Show persistent checklist sidebar for users who skip onboarding
- Display warnings about limited functionality until setup is complete
- Replace logo with "OROSHI" text using a stylish free font (similar to Sagittaire)
- Ensure Ruby 4.0.0 compatibility and `./bin/dev` runs without errors

## User Stories

### Phase 0: Foundation

#### US-001: Ensure dashboard loads without data
**Description:** As a new user, I want the dashboard to load without errors even when no data exists.

**Acceptance Criteria:**
- [ ] Dashboard index action handles nil/empty associations gracefully
- [ ] All dashboard partials render without errors when collections are empty
- [ ] Empty state messages shown where appropriate (e.g., "No suppliers yet")
- [ ] `./bin/dev` starts without errors on Ruby 4.0.0
- [ ] Typecheck passes

#### US-002: Replace logo with OROSHI text
**Description:** As a user, I want to see "OROSHI" text branding instead of the current logo.

**Acceptance Criteria:**
- [ ] Remove `<div id="logo">` from navbar
- [ ] Add "OROSHI" text with stylish free font (e.g., Cormorant Garamond, Playfair Display, or similar)
- [ ] Font loaded via Google Fonts or self-hosted
- [ ] Text links to root path like current logo
- [ ] Responsive sizing for mobile/desktop
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### Phase 1: Onboarding Infrastructure

#### US-003: Create onboarding progress tracking model
**Description:** As a developer, I need to track user onboarding progress in the database.

**Acceptance Criteria:**
- [ ] Create `OnboardingProgress` model with fields: `user_id`, `completed_at`, `skipped_at`, `current_step`, `completed_steps` (array/jsonb)
- [ ] Add associations: User `has_one :onboarding_progress`
- [ ] Generate and run migration successfully
- [ ] Add helper methods: `completed?`, `skipped?`, `step_completed?(step_name)`
- [ ] Typecheck passes

#### US-004: Create onboarding controller with step navigation
**Description:** As a developer, I need a controller to manage the onboarding wizard flow.

**Acceptance Criteria:**
- [ ] Create `Oroshi::OnboardingController` with actions: `index`, `step`, `complete_step`, `skip`, `resume`
- [ ] Define step order constant with phase groupings
- [ ] Redirect to onboarding if user has incomplete progress and not skipped
- [ ] Allow access to dashboard at any time via skip
- [ ] Typecheck passes

#### US-005: Create fullscreen wizard layout
**Description:** As a user, I want a clean fullscreen wizard experience for onboarding.

**Acceptance Criteria:**
- [ ] Create `layouts/onboarding.html.erb` - fullscreen, minimal chrome
- [ ] Include progress indicator showing current phase and step
- [ ] Add "Skip for now" button that goes to dashboard
- [ ] Add "Back" and "Next/Save" navigation buttons
- [ ] Style consistent with Oroshi branding
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### Phase 2: Supply Chain Setup Steps

#### US-006: Company info step (ホーム)
**Description:** As a user, I want to enter my company information as the first onboarding step.

**Acceptance Criteria:**
- [ ] Step displays company settings form (reuse existing `dashboard/home/company` partial or create simplified version)
- [ ] Required fields: company name, address basics
- [ ] Saving marks step complete and advances to next
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-007: Supply reception time step (供給受付時間)
**Description:** As a user, I want to set up material reception times for tracking supplies.

**Acceptance Criteria:**
- [ ] Step to create at least one `SupplyReceptionTime`
- [ ] Form fields: hour, time_qualifier
- [ ] Can add multiple reception times
- [ ] At least one required to proceed
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-008: Supplier organization step (供給組織)
**Description:** As a user, I want to create at least one supplier organization.

**Acceptance Criteria:**
- [ ] Step to create `SupplierOrganization`
- [ ] Required fields: entity_type, entity_name, country_id, subregion_id, invoice_number, fax, free_entry
- [ ] Dynamic subregion dropdown based on country selection
- [ ] Associate with reception times created in previous step
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-009: Supplier step (供給者)
**Description:** As a user, I want to create at least one supplier within an organization.

**Acceptance Criteria:**
- [ ] Step to create `Supplier` under the organization from previous step
- [ ] Required fields per Supplier model validations
- [ ] Can add multiple suppliers
- [ ] At least one required to proceed
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-010: Supply type step (供給種類)
**Description:** As a user, I want to create at least one supply type for tracking materials.

**Acceptance Criteria:**
- [ ] Step to create `SupplyType`
- [ ] Required fields: name, units, handle, liquid (boolean)
- [ ] Example placeholders for common supply types
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-011: Supply type variation step (変種)
**Description:** As a user, I want to create at least one variation for my supply type.

**Acceptance Criteria:**
- [ ] Step to create `SupplyTypeVariation` for supply type from previous step
- [ ] Required fields: name, default_container_count
- [ ] Associate with suppliers (multi-select)
- [ ] At least one required to proceed
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### Phase 3: Sales/Order Setup Steps

#### US-012: Buyer step
**Description:** As a user, I want to create at least one buyer to sell to.

**Acceptance Criteria:**
- [ ] Step to create `Buyer`
- [ ] Required fields: name, handle, handling_cost, daily_cost, entity_type, optional_cost, commission_percentage, color
- [ ] Color picker for buyer color
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-013: Product step
**Description:** As a user, I want to create at least one product.

**Acceptance Criteria:**
- [ ] Step to create `Product` linked to a supply type
- [ ] Required fields: name, units, supply_type_id, dimensions (can default to 0)
- [ ] Select from supply types created earlier
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-014: Product variation step
**Description:** As a user, I want to create at least one product variation.

**Acceptance Criteria:**
- [ ] Step to create `ProductVariation` for product from previous step
- [ ] Link to supply type variations (multi-select)
- [ ] Required fields per model validations
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-015: Shipping organization step
**Description:** As a user, I want to create at least one shipping organization.

**Acceptance Criteria:**
- [ ] Step to create `ShippingOrganization`
- [ ] Required fields: name, handle
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-016: Shipping method step
**Description:** As a user, I want to create at least one shipping method.

**Acceptance Criteria:**
- [ ] Step to create `ShippingMethod` for shipping organization
- [ ] Required fields: name, handle, shipping_organization_id, daily_cost, per_shipping_receptacle_cost, per_freight_unit_cost
- [ ] Associate with buyers (multi-select)
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-017: Shipping receptacle step
**Description:** As a user, I want to create at least one shipping receptacle (box/container).

**Acceptance Criteria:**
- [ ] Step to create `ShippingReceptacle`
- [ ] Required fields: name, handle, cost, default_freight_bundle_quantity, dimensions
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-018: Order category step
**Description:** As a user, I want to create at least one order category.

**Acceptance Criteria:**
- [ ] Step to create `OrderCategory`
- [ ] Required fields: name, color
- [ ] Color picker for category color
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### Phase 4: Checklist Sidebar

#### US-019: Create checklist sidebar component
**Description:** As a user who skipped onboarding, I want to see a persistent checklist of incomplete setup steps.

**Acceptance Criteria:**
- [ ] Sidebar component shows on dashboard when onboarding incomplete and skipped
- [ ] Lists all steps grouped by phase with completion status
- [ ] Clicking incomplete step opens that step in wizard
- [ ] Dismiss button with warning modal explaining limited functionality
- [ ] Sidebar hidden when all steps complete or dismissed
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-020: Add functionality warnings to checklist
**Description:** As a user, I want to understand what functionality is limited until I complete setup.

**Acceptance Criteria:**
- [ ] Phase 1 (Supply Chain) incomplete: "Cannot create material tracking invoices"
- [ ] Phase 2 (Sales) incomplete: "Cannot create orders"
- [ ] Warnings shown in dismiss confirmation modal
- [ ] Warnings shown inline on checklist sidebar
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

#### US-021: Persist checklist dismissal
**Description:** As a user, I want my dismissal of the checklist to be remembered.

**Acceptance Criteria:**
- [ ] Add `checklist_dismissed_at` to OnboardingProgress
- [ ] Migration to add column
- [ ] Dismissal persists across sessions
- [ ] Can re-enable checklist from settings or menu
- [ ] Typecheck passes

## Functional Requirements

- FR-1: Dashboard must render without errors when all Oroshi models have zero records
- FR-2: New users see onboarding wizard on first login
- FR-3: Users can skip onboarding at any time and access dashboard
- FR-4: Skipped users see persistent checklist sidebar until complete or dismissed
- FR-5: Steps can be completed in order within each phase
- FR-6: Completing all steps marks onboarding as complete
- FR-7: Logo replaced with "OROSHI" text in stylish free font
- FR-8: Application runs on Ruby 4.0.0 with `./bin/dev`

## Non-Goals

- Multi-language onboarding (Japanese only for now)
- Video tutorials or animated guides
- Importing data from external systems
- Bulk creation of entities in onboarding steps
- Mobile-specific onboarding UI (responsive is sufficient)

## Technical Considerations

- Reuse existing form partials where possible to maintain consistency
- OnboardingProgress uses JSONB for completed_steps for flexibility
- Stimulus controller for wizard navigation and progress updates
- Turbo Frames for step content loading without full page refresh
- Font: Playfair Display Black 900, custom kerning (tight letter-spacing), reduced leading

## Success Metrics

- New users can complete onboarding and create first order in under 15 minutes
- Dashboard loads without errors for users with no data
- Users understand what steps remain via checklist
- Onboarding can be resumed if browser closed mid-flow

## Open Questions

- Should we allow editing previously completed steps from within the wizard?
- Should supply reception times be optional or required?
- Exact font choice for "OROSHI" branding - user to select from options
