# Phase 3: Views, Assets & Helpers - Summary

## Overview
Phase 3 extracts all views, assets, helpers, and locale files for the Oroshi engine.

## Status: ✅ COMPLETE

All files are already in the correct locations for a Rails engine:

### Views (263 files)
Location: `app/views/oroshi/`
- All views properly namespaced under oroshi/
- 30+ view directories covering all features
- Includes partials, layouts, and shared components

### Helpers (6 modules)
Location: `app/helpers/oroshi/`
- dashboard_helper.rb
- onboarding_helper.rb
- orders_helper.rb  
- payment_receipts_helper.rb
- supplies_helper.rb
- supply_date_helper.rb

### Assets
**Stylesheets** (`app/assets/stylesheets/`):
- application.scss (main stylesheet)
- _oroshi_utilities.scss (utility classes)
- funabiki.scss
- onboarding.scss
- scaffolds.scss

**JavaScript** (`app/javascript/controllers/oroshi/`):
- Stimulus controllers for interactive features
- addresses_controller.js
- dashboard_controller.js
- orders/ (directory with multiple controllers)
- payment_receipts/ (directory)
- product_variations/ (directory)
- suppliers/ (directory)
- supplies/ (directory)
- positionable_controller.js
- supply_settings_form_controller.js

**Images** (`app/assets/images/`):
- 35+ PNG/SVG images
- Logos, icons, placeholders

**Fonts** (`app/assets/fonts/`):
- MPLUS1p-Bold.ttf (1.7MB)
- MPLUS1p-Light.ttf (1.7MB)
- MPLUS1p-Regular.ttf (1.7MB)
- SawarabiMincho-Regular.ttf (1.0MB)
- TakaoPMincho.ttf (7.6MB)
- **Total: ~14MB** of Japanese fonts

### Locales (21 files)
Location: `config/locales/`
- ja.yml (main Japanese translations)
- en.yml (English translations)
- oroshi.ja.yml (Oroshi-specific Japanese)
- oroshi.hints.ja.yml (form hints)
- models.ja.yml (model translations)
- devise.ja.yml, devise.en.yml (authentication)
- Subdirectories: ja/, en/

### Asset Pipeline Configuration

**Propshaft** (Modern asset pipeline):
- Serves all assets from app/assets/ directories
- No compilation needed for CSS (dartsass-rails handles SCSS)
- manifest.js declares asset trees

**Importmap** (JavaScript dependencies):
- config/importmap.rb defines pins
- Uses CDN for Bootstrap, FullCalendar, Flatpickr, etc.
- Vendored: fullcalendar, moment, chartkick

### Font Helper Module

Created `lib/oroshi/fonts.rb` for Prawn PDF generation:
```ruby
module Oroshi
  module Fonts
    def self.font_path(font_name)
      Oroshi::Engine.root.join("app/assets/fonts/#{font_name}").to_s
    end
    
    def self.configure_prawn_fonts(pdf)
      # Configures MPLUS1p, SawarabiMincho, TakaoPMincho
    end
  end
end
```

## Engine Configuration

The engine.rb already configures:
- i18n load paths for locales
- Importmap paths for JavaScript
- Asset precompilation for CSS/JS
- Autoload paths for helpers

## Verification

All assets, views, helpers, and locales will be automatically included in the gem because they're in standard Rails engine locations:
- `app/views/` → automatically served by engine
- `app/helpers/` → automatically loaded
- `app/assets/` → served by Propshaft
- `config/locales/` → loaded by i18n initializer

## Next Steps

Phase 4 will extract background jobs and Solid Queue configuration.
