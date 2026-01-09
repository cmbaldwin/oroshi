# User Onboarding & Dashboard Setup - Fix Plan

Step-by-step wizard for new users with persistent checklist sidebar.

## Phase 0: Foundation
- [x] US-001: Ensure dashboard loads without data (Priority 1)
- [ ] US-002: Replace logo with OROSHI text (Priority 2)
- [ ] US-003: Create onboarding progress tracking model (Priority 3)
- [ ] US-004: Create onboarding controller with step navigation (Priority 4)
- [ ] US-005: Create fullscreen wizard layout (Priority 5)
- [ ] US-006: Add before_action to redirect incomplete users to onboarding (Priority 6)

## Phase 1: Supply Chain Setup Steps
- [ ] US-007: Company info onboarding step (Priority 7)
- [ ] US-008: Supply reception time onboarding step (Priority 8)
- [ ] US-009: Supplier organization onboarding step (Priority 9)
- [ ] US-010: Supplier onboarding step (Priority 10)
- [ ] US-011: Supply type onboarding step (Priority 11)
- [ ] US-012: Supply type variation onboarding step (Priority 12)

## Phase 2: Sales/Orders Setup Steps
- [ ] US-013: Buyer onboarding step (Priority 13)
- [ ] US-014: Product onboarding step (Priority 14)
- [ ] US-015: Product variation onboarding step (Priority 15)
- [ ] US-016: Shipping organization onboarding step (Priority 16)
- [ ] US-017: Shipping method onboarding step (Priority 17)
- [ ] US-018: Shipping receptacle onboarding step (Priority 18)
- [ ] US-019: Order category onboarding step (Priority 19)

## Phase 3: Post-Onboarding Features
- [ ] US-020: Create checklist sidebar component (Priority 20)
- [ ] US-021: Add functionality warnings and dismissal persistence (Priority 21)

---

## Current Focus: US-002 - Replace logo with OROSHI text

### Requirements
1. Remove <div id='logo'> from navbar partial
2. Add 'OROSHI' text with Playfair Display Black 900 font
3. Apply tight letter-spacing and reduced line-height
4. Font loaded via Google Fonts
5. Text links to root path like current logo
6. Responsive sizing for mobile/desktop
7. Typecheck passes

---

## Completed

### US-001 - Ensure dashboard loads without data ✅
- Dashboard partials already handle empty collections gracefully
- Tests confirm all routes return success with empty data
- Fixed test path issues in dashboard_controller_test.rb
