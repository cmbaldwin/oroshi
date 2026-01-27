# Research Plan: Testing Gem Installation & Integration

**Research Date:** January 25, 2026  
**Purpose:** Understand how mature Rails engine gems handle installation testing and configuration

## Problem Statement

The Oroshi gem works in the generated sandbox (`bin/sandbox`) but fails when installed in a separate Rails application (oroshi-moab) using the repo as a gem source. This suggests potential issues with:

- **Namespace isolation** - Engine routes vs host app routes conflicts
- **Route configuration** - Dual routes setup (engine vs standalone)
- **Asset loading** - Propshaft/importmap failing when standalone routes loaded
- **Dependency management** - Gem initialization order issues
- **Installation instructions** - Missing steps or incorrect order
- **Configuration requirements** - Conditional initializers not documented

## Recent Discovery (January 25, 2026)

Ralph's autonomous testing iteration revealed a **critical infrastructure issue**:

**Problem:** Engine routes (`config/routes.rb`) conflict with standalone app routes (`config/routes_standalone_app.rb`)

**Symptom:** Asset loading errors occur when standalone routes are loaded in test environment

**Impact:** Blocked US-016 through US-022 (orders dashboard system tests)

**Investigation:** Documented in `.ralph/progress.txt` at timestamp [2026-01-25 13:31:00]

This suggests the dual-route configuration pattern may be contributing to the oroshi-moab installation failure.

## Research Questions

### 1. How do established gems test installation?

**Gems to study:**

- **Solidus** - E-commerce platform (similar complexity to Oroshi)
- **Spree** - E-commerce platform (original inspiration for Solidus)
- **Devise** - Authentication engine
- **ActiveAdmin** - Admin framework engine
- **RailsAdmin** - Admin framework engine

**What to look for:**

- Do they have installation tests separate from sandbox tests?
- How do they verify the gem works in a fresh Rails app?
- What testing patterns do they use (integration tests, E2E, manual checklist)?
- **NEW:** How do they handle dual configurations (engine vs standalone)?

### 2. How do they handle engine vs standalone routing?

**Critical investigation based on Ralph's findings:**

**Pattern to research:**

- Do mature gems use dual route files like Oroshi?
- How do they prevent route conflicts in test environments?
- How do they ensure assets load regardless of routing configuration?
- Do they use environment-specific route loading?

**Oroshi's current approach:**

```ruby
# config/routes.rb - Engine routes (mounted in host app)
Oroshi::Engine.routes.draw do
  # Engine-specific routes
end

# config/routes_standalone_app.rb - Standalone routes (for sandbox)
Rails.application.routes.draw do
  mount Oroshi::Engine, at: '/'
  # Additional standalone routes
end
```

**Questions:**

- Is this dual-file pattern common in Rails engines?
- Should standalone routes only load in development/test for sandbox?
- Should we consolidate routing or improve environment detection?

### 3. What installation steps need testing?

**Based on Oroshi's README installation process:**

1. Adding gem to Gemfile (from git repo vs from RubyGems)
2. Running `bundle install`
3. Running installer: `bin/rails generate oroshi:install`
4. Running migrations: `bin/rails oroshi:install:migrations && bin/rails db:migrate`
5. Mounting engine in routes: `mount Oroshi::Engine, at: '/oroshi'`
6. Loading Solid schemas (queue, cache, cable)
7. Seeding data (optional)

**Potential failure points (updated with Ralph's findings):**

- Generator doesn't copy files correctly
- Migrations reference models before engine initialized ✅ **Documented in REALIZATIONS.md**
- **Routes conflict with host app routing** ⚠️ **NEW FINDING**
- **Assets don't load when engine mounted** ⚠️ **NEW FINDING**
- Initializers fail (gem dependencies not loaded) ✅ **Documented in REALIZATIONS.md**
- I18n files not found (locale loading)

### 4. How do they test namespace isolation?

**Key questions:**

- How do they prevent `Oroshi::` namespace from conflicting with host app models?
- How do they test that `main_app.` routing helpers work correctly? ✅ **Documented in REALIZATIONS.md**
- How do they verify engine routes don't leak into host app?
- **NEW:** How do they prevent route configuration conflicts?

### 5. What CI/CD patterns exist for gem installation testing?

**Look for:**

- GitHub Actions workflows that test installation
- Matrix testing (multiple Rails versions, Ruby versions)
- "Install and smoke test" scripts
- Docker-based installation testing
- **NEW:** Automated testing of gem in fresh Rails app (not just sandbox)

## Research Tasks

### Task 1: Study Solidus Installation Testing

**Files to examine:**

- `solidus/.github/workflows/` - CI configuration
- `solidus/guides/installation/` - Installation docs
- `solidus/lib/generators/solidus/install/` - Install generator
- Any `test/installation/` or `spec/installation/` directories
- **NEW:** Route configuration patterns (engine vs standalone)
- **NEW:** Asset pipeline setup for mounted engines

**Document:**

- How they test a fresh install works
- What their install generator does
- Any automated installation verification
- **NEW:** How they handle routing in different environments
- **NEW:** Asset loading patterns when mounted

### Task 2: Study Devise Installation Testing

**Files to examine:**

- `devise/.github/workflows/` - CI setup
- `devise/lib/generators/devise/install/` - Install generator
- `devise/test/` or `devise/spec/` - Test patterns

**Document:**

- How they verify engine mounting works
- How they test initializer generation
- Pattern for testing `devise_for` routing helpers
- **NEW:** Do they use separate route files for different environments?

### Task 3: Study Spree/ActiveAdmin/RailsAdmin

**Quick scan for:**

- Installation test patterns
- Generator testing approaches
- CI workflows for installation verification
- **NEW:** Dual configuration patterns (if any)
- **NEW:** Asset pipeline handling in mounted engines

### Task 4: Analyze Oroshi vs Sandbox Differences

**Compare:**

- `oroshi/bin/sandbox` script (what it does)
- `oroshi/README.md` installation steps
- oroshi-moab actual setup (what failed)
- **NEW:** `config/routes.rb` vs `config/routes_standalone_app.rb`
- **NEW:** Asset loading in sandbox vs mounted gem

**Document discrepancies:**

- Steps sandbox does that README doesn't mention
- Configuration sandbox generates vs manual setup
- Timing issues (when to load what)
- **NEW:** Route file loading logic
- **NEW:** Environment-specific configurations
- **NEW:** Asset compilation differences

### Task 5: Review Oroshi Error Logs from oroshi-moab

**Gather from oroshi-moab:**

- Server startup errors
- Asset compilation errors
- Routing errors (404s, namespace issues)
- Database/migration errors
- **NEW:** Route loading errors
- **NEW:** Propshaft/importmap errors

### Task 6: Investigate Ralph's Test Infrastructure Block

**Review Ralph's investigation:**

- Read `.ralph/progress.txt` [2026-01-25 13:31:00]
- Understand exact error when loading standalone routes
- Document what works vs what fails
- Identify root cause of route/asset conflict

**Questions to answer:**

- Why do standalone routes cause asset loading to fail?
- Is this a test-only issue or would it affect production?
- How does sandbox avoid this issue?
- What's the correct pattern for dual configurations?

## Deliverables

### 1. Research Document

File: `.ralph/research/findings-gem-installation-testing.md`

Contains:

- Summary of how 5+ gems test installation
- Common patterns identified
- **Routing configuration patterns (engine vs standalone)**
- **Asset pipeline patterns for mounted engines**
- Recommended approach for Oroshi
- Code examples from other gems

### 2. Gap Analysis

File: `.ralph/research/oroshi-installation-gaps.md`

Contains:

- What sandbox does that installation doesn't
- Missing steps in README
- Configuration differences
- **Route configuration issues**
- **Asset loading discrepancies**
- Failure points in oroshi-moab
- **Ralph's test infrastructure findings**

### 3. Route Architecture Analysis

File: `.ralph/research/route-configuration-analysis.md`

Contains:

- Current dual-route pattern explanation
- Why it works in sandbox but not mounted gem
- Industry patterns from mature gems
- Proposed solutions with trade-offs
- Migration path from current to recommended pattern

### 4. PRD Outline

File: `.ralph/research/prd-outline-installation-testing.md`

Contains:

- User stories for installation testing
- User stories for route refactoring (if needed)
- Acceptance criteria templates
- Priority ordering
- Estimated complexity
- Dependencies on route architecture decisions

## Next Steps

After research is complete:

1. **Review findings** - Validate research quality and completeness
2. **Make architectural decision** - Choose route configuration pattern
3. **Create PRD** - Use `/ralph` skill to convert outline to prd.json
4. **Implement route refactoring** - If needed based on research
5. **Implement installation tests** - Let Ralph autonomously build tests
6. **Update README** - Fix any missing/incorrect installation steps
7. **Test in oroshi-moab** - Verify fixes resolve real-world installation issues
8. **Unblock US-016** - Resume dashboard testing once infrastructure fixed

## Success Criteria

Research is complete when we can answer:

- ✅ How do mature gems test installation?
- ✅ What specific steps in Oroshi installation could fail?
- ✅ What's the difference between sandbox and real installation?
- ✅ What testing approach should Oroshi use?
- ✅ **How should engines handle routing (single file vs dual file)?**
- ✅ **Why does standalone route loading break assets?**
- ✅ **What's the correct pattern to support both engine and standalone modes?**
- ✅ Do we have enough information to write a comprehensive PRD?

## Priority Issues Identified

Based on Ralph's findings, the research should prioritize:

1. **CRITICAL:** Route configuration patterns (dual files causing test failures)
2. **HIGH:** Asset loading when engine mounted vs standalone
3. **HIGH:** Installation testing automation (sandbox works, real install fails)
4. **MEDIUM:** Generator completeness verification
5. **MEDIUM:** Documentation gaps in README

---

**Status:** Ready for research (updated with Ralph findings)  
**Estimated effort:** 3-5 hours research + 2 hours documentation  
**Next action:** Begin Task 1 (Solidus study) with focus on routing patterns  
**Blocker for:** US-016 through US-022 (dashboard tests)  
**Related issue:** oroshi-moab installation failure
