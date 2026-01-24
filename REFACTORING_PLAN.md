# Oroshi Refactoring Plan

## Overview

This document outlines a phased approach to address critical issues and follow Rails engine best practices (inspired by Spree, Solidus).

## Current Issues

### 1. Authentication & Authorization

- [ ] Users created in seeds need proper approval/confirmation
- [ ] All controllers need consistent authentication rules
- [ ] Admin should have unrestricted access
- [ ] Need role-based access control UI for admin

### 2. Helper Methods & Namespacing

- [ ] Remove unused helper methods from ApplicationHelper
- [ ] Fix namespacing to follow gem best practices
- [ ] Ensure helpers are properly scoped to Oroshi module
- [ ] Remove hardcoded company information

### 3. Missing Calendar Functionality

- [ ] Re-implement `japanese_holiday_background_events`
- [ ] Re-implement `get_ichiba_holidays`
- [ ] Fix supplies calendar page

## Phased Implementation Plan

### Phase 1: Critical Fixes (Immediate)

**Goal:** Make the system functional and secure

#### 1.1 Authentication & Seeds

- Fix user seeds to set `approved: true`, `confirmed_at: Time.current`
- Add `check_admin` before_action to admin-only controllers
- Ensure all Oroshi controllers inherit proper authentication

#### 1.2 Calendar Functionality

- Move calendar helper methods to `Oroshi::SuppliesHelper`
- Re-implement japanese_holiday_background_events
- Extract to a service object if complex

#### 1.3 Anonymous Company Data

- Replace hardcoded company info with placeholder data
- Use I18n for company information strings

### Phase 2: Helper Cleanup (Short-term)

**Goal:** Remove technical debt and unused code

#### 2.1 Audit Helper Methods

Categorize helpers into:

- **Keep:** Used in views/controllers
- **Move:** Should be in Oroshi module
- **Remove:** Unused or business-specific

#### 2.2 Business-Specific Helpers to Remove

These are highly specific to a single business:

- `online_order_counts` - Yahoo-specific oyster counting
- `yahoo_knife_counts` - Yahoo-specific
- `yahoo_order_counts` - Yahoo-specific with hardcoded item IDs
- `infomart_count_*` - Infomart marketplace specific
- `get_infomart_backend_link` - External service specific
- `exp_card_popover` - Very specific expiration card logic

#### 2.3 Helpers to Keep (Generic)

- Date formatting: `to_nengapi`, `to_gapi`, `weekday_japanese`, etc.
- Currency: `yenify`, `yenify_with_decimal`
- Icons: `icon` method
- Settings: `company_setting`, `get_setting`, etc.

#### 2.4 Helpers to Move to Oroshi Module

Move to `Oroshi::ApplicationHelper`:

- All generic helpers currently in ApplicationHelper
- Ensure proper module namespacing

### Phase 3: Namespacing & Structure (Medium-term)

**Goal:** Follow Rails engine best practices like Spree/Solidus

#### 3.1 Module Structure

```
lib/oroshi/
  core/
    lib/oroshi/core/engine.rb
  frontend/
  backend/
```

#### 3.2 Helper Organization

```
app/helpers/
  oroshi/
    application_helper.rb  # Core generic helpers
    orders_helper.rb       # Order-specific
    supplies_helper.rb     # Supply-specific
    dashboard_helper.rb    # Dashboard-specific
```

#### 3.3 Controller Authentication

- Base controller: `Oroshi::BaseController`
- Admin controller: `Oroshi::Admin::BaseController` (requires admin)
- Public controller: `Oroshi::PublicController` (no auth required)

### Phase 4: Role-Based Access Control (Long-term)

**Goal:** Flexible permission system

#### 4.1 Permission Model

- Create `Oroshi::Permission` model
- Create `Oroshi::RolePermission` join table
- Seed default permissions for roles

#### 4.2 Admin UI

- Dashboard page for managing role permissions
- Controller/Action based permissions
- Visual matrix of role → controller → action

#### 4.3 Authorization Layer

- Use Pundit or implement simple policy objects
- Controller concern for authorization
- Permission caching

## Best Practices from Spree/Solidus

### 1. Modular Structure

- Separate core, frontend, backend, API
- Each component is a separate engine
- Clean dependencies

### 2. Decorator Pattern

- Allow host app to override/extend
- Use class_eval for decorators
- Clear extension points

### 3. Preferences/Settings

- Centralized configuration
- Type-safe preference system
- Environment-specific defaults

### 4. Helper Organization

- Namespace all helpers
- Specific helpers for specific concerns
- Avoid monolithic helper files

### 5. Controller Structure

```ruby
module Oroshi
  class BaseController < ApplicationController
    before_action :authenticate_user!

    helper 'oroshi/application'

    layout 'oroshi/application'
  end

  module Admin
    class BaseController < Oroshi::BaseController
      before_action :check_admin

      layout 'oroshi/admin'
    end
  end
end
```

## Implementation Order

1. **Week 1: Critical Fixes**
   - Fix authentication
   - Fix seeds
   - Re-implement calendar methods
   - Replace company info

2. **Week 2: Helper Cleanup**
   - Audit all helpers
   - Remove unused methods
   - Move business-specific to examples

3. **Week 3: Namespacing**
   - Reorganize helper modules
   - Create proper base controllers
   - Update all controllers to inherit correctly

4. **Week 4+: RBAC**
   - Design permission model
   - Implement admin UI
   - Add authorization layer

## Files to Modify

### Immediate

- `db/seeds.rb` - Fix user creation
- `app/helpers/application_helper.rb` - Remove unused, add calendar methods
- `app/controllers/application_controller.rb` - Clean up auth
- `app/controllers/oroshi/supplies_controller.rb` - Fix calendar

### Short-term

- All helper files
- All controller files
- Layout files

### Long-term

- New permission models
- New admin controllers
- Migration to modular structure
