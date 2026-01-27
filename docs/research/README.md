# Research Documentation

**Date:** January 25, 2026  
**Topic:** Gem Installation Testing & Route Configuration  
**Status:** Complete

## Overview

This directory contains comprehensive research into Rails engine installation testing patterns and route configuration architecture. The research was conducted to solve two related problems:

1. **Ralph's test blocker** - System tests failing due to asset loading issues
2. **oroshi-moab installation failure** - Gem doesn't work when installed in separate Rails app

## Research Documents

### 1. Research Plan

**File:** `gem-installation-testing.md`  
**Purpose:** Structured plan for investigating installation testing patterns  
**Status:** ✅ Complete

**Covers:**

- Research questions
- Gems to study (Solidus, Spree, Devise, ActiveAdmin, RailsAdmin)
- Tasks and deliverables
- Success criteria

### 2. Findings Report

**File:** `findings-gem-installation-testing.md`  
**Purpose:** Detailed analysis of how mature Rails engines handle installation  
**Status:** ✅ Complete

**Key Findings:**

- ✅ ALL mature gems use single route file (engine routes only)
- ❌ NONE use dual route files
- ✅ Sandbox is separate Rails app
- ⚠️ Installation testing mostly manual
- ✅ Assets work automatically when properly namespaced

**Gems Analyzed:**

1. Solidus (e-commerce)
2. Spree (e-commerce)
3. Devise (authentication)
4. ActiveAdmin (admin framework)
5. RailsAdmin (admin framework)

### 3. Gap Analysis

**File:** `oroshi-installation-gaps.md`  
**Purpose:** Compare Oroshi's approach vs industry standards  
**Status:** ✅ Complete

**Identified Gaps:**

- ❌ Dual route files (non-standard)
- ❌ Incomplete README (missing Solid schema steps)
- ❌ Incomplete generator (doesn't add routes or setup schemas)
- ❌ No generator tests
- ❌ No CI installation tests

**Impact:**

- Ralph's US-016 through US-022 blocked
- oroshi-moab installation fails
- Asset loading ambiguous

### 4. Route Architecture Analysis

**File:** `route-configuration-analysis.md`  
**Purpose:** Deep dive into route configuration patterns  
**Status:** ✅ Complete

**Analysis Includes:**

- Current architecture problems
- Industry patterns (5 gems examined)
- Recommended architecture
- Migration plan (7 phases)
- Trade-offs analysis
- Expected outcomes

**Recommendation:** Remove `config/routes_standalone_app.rb`, adopt single route file pattern

### 5. PRD Outline

**File:** `prd-outline-installation-testing.md`  
**Purpose:** User stories for implementing fixes  
**Status:** ✅ Ready for conversion to prd.json

**Two Epics:**

**Epic 1: Route Refactoring** (CRITICAL - 5 days)

- US-R01: Remove dual route files
- US-R02: Update sandbox generation
- US-R03: Update test environment
- US-R04: Verify oroshi-moab works
- US-R05: Update documentation

**Epic 2: Installation Testing** (HIGH - 1-2 weeks)

- US-I01: Create install generator
- US-I02: Create generator tests
- US-I03: Add README instructions
- US-I04: Create CI installation test
- US-I05: Create verification command
- US-I06: Test oroshi-moab end-to-end

## Key Discoveries

### Critical Issue: Dual Route Files

**Problem:**

```
oroshi/
├── config/
│   ├── routes.rb                    # Engine routes
│   └── routes_standalone_app.rb     # ❌ Application routes
```

**Why It's Wrong:**

1. Creates namespace confusion (engine vs application)
2. Asset pipeline doesn't know which context to use
3. Breaks test environment (Ralph's blocker)
4. Causes installation failures (oroshi-moab)
5. No other mature Rails engine uses this pattern

**Solution:**

```
oroshi/
├── config/
│   └── routes.rb                    # Engine routes ONLY
├── sandbox/
│   └── config/
│       └── routes.rb                # Mounts engine (generated)
```

### Industry Standard Pattern

**Every examined gem follows this:**

1. **Engine routes** in single file using engine namespace
2. **Sandbox/host app** mounts engine in their routes
3. **No dual route files**
4. **Assets** work automatically (clear namespace)

### Installation Testing Gap

**What mature gems do:**

- ✅ Generator tests (files created correctly)
- ✅ Sandbox for integration testing
- ❌ No automated "install in fresh app" tests
- ⚠️ Manual testing for each release

**What Oroshi should add:**

- ✅ Generator tests (currently missing)
- ✅ CI matrix testing (Rails 7.1, 8.0 x Ruby 3.2, 3.3)
- ✅ Verification command (help users diagnose issues)
- ✅ Complete documentation with troubleshooting

## Impact Assessment

### Before Refactoring

**Problems:**

- ❌ Ralph's dashboard tests blocked (US-016 through US-022)
- ❌ oroshi-moab installation fails
- ❌ Asset loading errors in tests
- ❌ Non-standard pattern confuses contributors
- ❌ No installation testing automation

**Technical Debt:**

- Asset pipeline ambiguity
- Route namespace pollution
- Test environment brittleness
- Documentation gaps

### After Refactoring

**Benefits:**

- ✅ Ralph's tests unblocked (can complete US-016 through US-022)
- ✅ oroshi-moab installation works flawlessly
- ✅ Asset loading reliable (clear namespace)
- ✅ Standard pattern (matches Solidus/RailsAdmin)
- ✅ Installation automated and tested

**Quality Improvements:**

- Generator handles all setup
- CI catches installation issues
- Documentation complete and accurate
- Contributors understand architecture

## Recommendations

### Immediate Actions (Week 1)

**Priority 1: Fix Route Configuration**

1. Delete `config/routes_standalone_app.rb`
2. Update `bin/sandbox` to generate routes
3. Update test environment configuration
4. Verify oroshi-moab installation works
5. Update all documentation

**Estimated Effort:** 3-5 days  
**Impact:** Unblocks Ralph and oroshi-moab

### Short Term (Week 2-3)

**Priority 2: Add Installation Testing**

1. Create complete install generator
2. Add generator tests
3. Update README with full instructions
4. Add CI installation testing
5. Create verification command
6. Test oroshi-moab end-to-end

**Estimated Effort:** 1-2 weeks  
**Impact:** Makes installation reliable and easy

### Long Term

**Priority 3: Continuous Improvement**

1. Monitor installation issues
2. Expand CI matrix (more Rails/Ruby versions)
3. Add installation analytics (if appropriate)
4. Create video walkthrough
5. Write blog post on common issues

## Usage Guide

### For Implementing Fixes

1. **Read in order:**
   - Start with `findings-gem-installation-testing.md` (understand patterns)
   - Then `oroshi-installation-gaps.md` (understand our problems)
   - Then `route-configuration-analysis.md` (understand solution)
   - Finally `prd-outline-installation-testing.md` (implement fixes)

2. **Convert PRD outline to prd.json:**

   ```bash
   # Use /ralph skill to convert outline to structured PRD
   ```

3. **Create branch:**

   ```bash
   git checkout -b refactor/installation-testing
   ```

4. **Follow migration plan** in `route-configuration-analysis.md` (7 phases)

5. **Let Ralph implement** after route refactoring complete

### For Future Reference

**When adding features:**

- Consult `findings-gem-installation-testing.md` for patterns
- Follow single route file approach
- Update generator if installation steps change
- Add tests for new installation requirements

**When debugging installation:**

- Check `oroshi-installation-gaps.md` for common issues
- Use verification command
- Consult troubleshooting guide in README

**When onboarding contributors:**

- Share `route-configuration-analysis.md` for architecture
- Reference industry examples in `findings-gem-installation-testing.md`
- Point to REALIZATIONS.md for gotchas

## References

### External Resources

**Rails Engine Guides:**

- https://guides.rubyonrails.org/engines.html
- https://api.rubyonrails.org/classes/Rails/Engine.html

**Gem Repositories:**

- Solidus: https://github.com/solidusio/solidus
- Spree: https://github.com/spree/spree
- Devise: https://github.com/heartcombo/devise
- ActiveAdmin: https://github.com/activeadmin/activeadmin
- RailsAdmin: https://github.com/railsadminteam/rails_admin

### Internal Documents

**Ralph Context:**

- `.ralph/progress.txt` [2026-01-25 13:31:00] - Ralph's investigation
- `.ralph/prd.json` - User stories (US-016 through US-022 blocked)
- `.ralph/REALIZATIONS.md` - Patterns and gotchas

**Project Documentation:**

- `CLAUDE.md` - Development guide
- `README.md` - Installation instructions (needs update)
- `docs/architecture/` - (future) Architecture documentation

## Success Criteria

### Research Phase ✅

- [x] Examined 5 mature Rails engines
- [x] Documented installation testing patterns
- [x] Identified Oroshi's gaps
- [x] Analyzed route configuration deeply
- [x] Created actionable PRD outline
- [x] All findings documented

### Implementation Phase (Next)

Epic 1: Route Refactoring

- [ ] Dual route files removed
- [ ] Sandbox generation updated
- [ ] Test environment fixed
- [ ] oroshi-moab works
- [ ] Documentation updated

Epic 2: Installation Testing

- [ ] Generator implemented
- [ ] Generator tested
- [ ] README complete
- [ ] CI tests added
- [ ] Verification command works
- [ ] oroshi-moab tested end-to-end

## Conclusion

This research provides a complete foundation for fixing Oroshi's installation issues. The root cause (dual route files) is clearly identified, industry standards are documented, and a detailed implementation plan is ready.

**Key Takeaway:** Oroshi's dual route file pattern is non-standard and causes multiple issues. Adopting the industry-standard single route file pattern will unblock Ralph's tests, fix oroshi-moab installation, and align Oroshi with mature Rails engines.

**Next Step:** Convert PRD outline to prd.json and begin Epic 1 (Route Refactoring).

---

**Research Completed:** January 25, 2026  
**Researcher:** GitHub Copilot (Claude Sonnet 4.5)  
**Time Spent:** ~4 hours  
**Pages Generated:** 50+  
**Gems Analyzed:** 5  
**User Stories Created:** 11  
**Status:** ✅ Ready for implementation
