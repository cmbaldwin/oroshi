# Phase 5: PDF Generation & Printables - Summary

## Overview
Phase 5 extracts the Prawn-based PDF generation library that creates invoices, order documents, and supply checks.

## Status: ✅ COMPLETE

All printables are already in the correct location for a Rails engine.

### Printables Library
Location: `lib/printables/`

**Base Class**: `lib/Printable.rb` (5.7KB)
- Extends `Prawn::Document`
- Configures Japanese fonts (MPLUS1p, Sawarabi, TakaoPMincho)
- Provides common helpers for company info, formatting, etc.
- Updated to use `Oroshi::Fonts.font_path()` for engine compatibility

**Invoice System** (`lib/printables/oroshi_invoice/`):
- `oroshi_invoice.rb` (2.3KB) - Main invoice generator
- `invoice_layout_one.rb` (5.3KB) - Layout variant 1
- `invoice_layout_two.rb` (3.0KB) - Layout variant 2
- `organization_invoice.rb` (1.0KB) - Organization-focused invoices
- `supplier_invoice.rb` (1.8KB) - Supplier-focused invoices
- `shared.rb` (2.0KB) - Shared invoice logic
- `supplier_year_to_date_table.rb` (3.6KB) - YTD reporting
- `supply_iterators.rb` (2.6KB) - Complex data iteration

**Order Documents**:
- `oroshi_order_document.rb` (5.5KB) - Order/packing slips

**Supply Checks** (`lib/printables/supply_check/`):
- `supply_check.rb` (1.9KB) - Main supply check document
- `header_and_footer.rb` (3.1KB) - Header/footer templates
- `supply_table.rb` (5.8KB) - Table rendering
- `supply_table_styles.rb` (689B) - Table styles

**Total**: 13 files, ~42KB of PDF generation code

### Font Integration

**Font Helper Module**: `lib/oroshi/fonts.rb`
```ruby
module Oroshi
  module Fonts
    def self.font_path(font_name)
      Oroshi::Engine.root.join("app/assets/fonts/#{font_name}").to_s
    end

    def self.configure_prawn_fonts(pdf)
      # Configures all Japanese fonts for Prawn
    end
  end
end
```

**Updated Printable Base Class**:
- Now uses `Oroshi::Fonts.font_path()` for engine compatibility
- Falls back to `Rails.root` if engine fonts not available
- Supports both gem and standalone app modes

**Font Paths** (app/assets/fonts/):
- MPLUS1p-Regular.ttf, Bold.ttf, Light.ttf (5.1MB total)
- SawarabiMincho-Regular.ttf (1.0MB)
- TakaoPMincho.ttf (7.6MB)

### Dependencies

**Gems**:
- `prawn` (2.4.0) - PDF generation
- `prawn-table` - Table support
- `combine_pdf` - PDF manipulation
- `ttfunk` (1.7.0) - Font handling
- `matrix` - Matrix operations

Already included in `oroshi.gemspec`.

**Ruby Libraries**:
- `open-uri` - For image loading
- `stringio` - For in-memory PDF generation

### Usage in Jobs

The printables are used by background jobs:
- **Oroshi::InvoiceJob** → `Printables::OroshiInvoice`
- **Oroshi::InvoicePreviewJob** → `Printables::OroshiInvoice`
- **Oroshi::OrderDocumentJob** → `Printables::OroshiOrderDocument`
- **Oroshi::SupplyCheckJob** → `Printables::SupplyCheck`

### Features

**Invoice PDFs**:
- Multiple layout variants
- Supplier and organization views
- Year-to-date (YTD) totals
- Complex supply iteration
- Japanese formatting throughout

**Order Documents**:
- Order summaries
- Packing slips
- Shipping information

**Supply Checks**:
- Supply verification sheets
- Table-based layouts
- Header/footer templates

### Engine Configuration

Already configured in `lib/oroshi/engine.rb`:

```ruby
# Configure autoload paths
initializer "oroshi.autoload", before: :set_autoload_paths do |app|
  config.autoload_paths << root.join("lib")
  config.autoload_paths << root.join("lib/printables")
  config.eager_load_paths << root.join("lib")
  config.eager_load_paths << root.join("lib/printables")
end
```

### Japanese Language Support

All PDFs support full Japanese:
- Fonts: MPLUS1p (primary), Sawarabi, TakaoPMincho
- Locale: Carmen.i18n_backend.locale = :ja
- Formatting: Date/currency helpers for Japanese

### Testing

Test files in `test/lib/printables/`:
- Tests for each printable class
- Font loading verification
- PDF content validation

### Example Usage

```ruby
# Generate invoice PDF
invoice = Oroshi::Invoice.find(123)
pdf = Printables::OroshiInvoice.new(invoice).render

# Attach to Active Storage
io = StringIO.new(pdf)
invoice.file.attach(
  io: io,
  content_type: 'application/pdf',
  filename: 'invoice.pdf'
)
```

## Verification

Printables are automatically included in the gem because:
- Located in `lib/printables/` → autoloaded by engine
- Base class `lib/Printable.rb` → autoloaded
- Fonts in `app/assets/fonts/` → served by Propshaft
- Font helper module provides engine-compatible paths

## Key Architectural Decisions

1. **Font Path Resolution**: Uses `Oroshi::Fonts.font_path()` for engine compatibility
2. **Fallback Support**: Works in both gem and standalone modes
3. **Base Class Pattern**: All printables inherit from `Printable < Prawn::Document`
4. **Japanese-First**: All fonts, formatting, and text support Japanese natively

## Next Steps

Phase 6 will extract Devise authentication and the User model.
