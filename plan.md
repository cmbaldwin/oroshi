# Plan: Comprehensive Export System for Oroshi

## Overview

Build a unified, extensible export system supporting **PDF, CSV, XLSX, and JSON** formats across all major data views: Order List, Daily Intake (Supply), Inventory, Factory Floor (Production), and Profit Calculation (Revenue). All exports are **async via Solid Queue** using the existing `Message` + `ActiveStorage` pattern.

---

## Architecture

### Current State

- `Printable` (base class, `lib/Printable.rb`) → extends `Prawn::Document` for PDF
- `OroshiOrderDocument`, `OroshiInvoice`, `SupplyCheck` — specific PDF generators in `lib/printables/`
- `Oroshi::OrderDocumentJob`, `Oroshi::InvoiceJob`, `Oroshi::SupplyCheckJob` — Solid Queue jobs
- `Message` model (parent app) — tracks job status via `state`, `message`, `data` (JSONB), `has_one_attached :stored_file`
- Shipping controller creates `Message`, enqueues job, job attaches PDF to `Message.stored_file`, sets `state: true`
- No CSV, XLSX, or JSON export infrastructure exists yet

### Target Architecture

```
lib/
  exports/                          # NEW: Export generator library
    base_export.rb                  # Abstract base with shared logic
    csv_export.rb                   # CSV generation mixin
    xlsx_export.rb                  # XLSX generation mixin
    json_export.rb                  # JSON generation mixin
    pdf_export.rb                   # PDF generation (wraps existing Printable)
    orders_export.rb                # Order list data export
    revenue_export.rb               # Profit/revenue data export
    production_export.rb            # Factory floor data export
    inventory_export.rb             # Inventory data export
    supply_export.rb                # Daily intake/supply data export
    shipping_export.rb              # Shipping chart data export (extends existing)

app/
  jobs/oroshi/
    export_job.rb                   # NEW: Unified export job (replaces per-type jobs pattern)

  controllers/oroshi/
    exports_controller.rb           # NEW: Handles export requests for all data types

  views/oroshi/exports/
    _export_button.html.erb         # NEW: Reusable export button partial (dropdown with format options)
    _date_range_export.html.erb     # NEW: Date range export modal/form

config/
  locales/
    exports.ja.yml                  # NEW: Japanese translations for export UI
```

### New Gem Dependency

Add to `Gemfile`:
```ruby
gem "caxlsx"  # Excel XLSX generation (community-maintained successor to axlsx)
```

---

## Step-by-Step Implementation

### Step 1: Add `caxlsx` gem

- Add `gem "caxlsx"` to `Gemfile`
- `bundle install`
- No initializer needed — `caxlsx` is a standalone library

### Step 2: Create `lib/exports/base_export.rb`

The abstract base class all exports inherit from. Handles:

- **Format dispatch**: `generate(format)` → delegates to `generate_csv`, `generate_xlsx`, `generate_json`, `generate_pdf`
- **Data loading**: Each subclass defines `load_data` to query and prepare records
- **Filter support**: Accepts a standardized `options` hash (buyer_ids, shipping_method_ids, order_category_ids, buyer_category_ids, date or date_range)
- **Column definitions**: Each subclass defines `columns` returning an array of `{ key:, header:, value: ->(record) {} }` hashes — used by CSV, XLSX, and JSON generators
- **Content type & filename helpers**: `content_type_for(format)`, `filename(format)`

```ruby
# lib/exports/base_export.rb
module Exports
  class BaseExport
    attr_reader :options, :records

    def initialize(options = {})
      @options = options.with_indifferent_access
      @records = load_data
    end

    def generate(format)
      send("generate_#{format}")
    end

    def filename(format)
      ext = { csv: "csv", xlsx: "xlsx", json: "json", pdf: "pdf" }[format.to_sym]
      "#{export_name}_#{date_label}_#{timestamp}.#{ext}"
    end

    def content_type(format)
      { csv: "text/csv", xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        json: "application/json", pdf: "application/pdf" }[format.to_sym]
    end

    private

    def load_data = raise NotImplementedError
    def columns = raise NotImplementedError
    def export_name = raise NotImplementedError

    def date_label
      if options[:start_date] && options[:end_date]
        "#{options[:start_date]}_#{options[:end_date]}"
      else
        options[:date] || Time.zone.today.to_s
      end
    end

    def timestamp = Time.zone.now.strftime("%Y%m%d%H%M%S")

    # Shared filter logic (mirrors OrdersDashboard::Shared#set_filters)
    def apply_order_filters(scope)
      scope = scope.where(buyer_id: options[:buyer_ids]) if options[:buyer_ids].present?
      scope = scope.where(shipping_method_id: options[:shipping_method_ids]) if options[:shipping_method_ids].present?
      if options[:order_category_ids].present?
        scope = scope.joins(:order_categories).where(order_categories: { id: options[:order_category_ids] })
      end
      if options[:buyer_category_ids].present?
        scope = scope.joins(buyer: :buyer_categories).where(buyer_categories: { id: options[:buyer_category_ids] })
      end
      scope
    end
  end
end
```

### Step 3: Create format mixin modules

**`lib/exports/csv_export.rb`** — included in `BaseExport`:
```ruby
module Exports
  module CsvExport
    def generate_csv
      require "csv"
      CSV.generate do |csv|
        csv << columns.map { |c| c[:header] }
        records.each { |r| csv << columns.map { |c| c[:value].call(r) } }
      end
    end
  end
end
```

**`lib/exports/xlsx_export.rb`**:
```ruby
module Exports
  module XlsxExport
    def generate_xlsx
      package = Caxlsx::Package.new
      workbook = package.workbook
      workbook.add_worksheet(name: export_name) do |sheet|
        # Header row with bold style
        header_style = workbook.styles.add_style(b: true, bg_color: "F0F0F0")
        sheet.add_row columns.map { |c| c[:header] }, style: header_style

        # Currency style for yen columns
        yen_style = workbook.styles.add_style(format_code: '¥#,##0')

        records.each do |record|
          values = columns.map { |c| c[:value].call(record) }
          styles = columns.map { |c| c[:type] == :currency ? yen_style : nil }
          sheet.add_row values, style: styles
        end
      end
      stream = package.to_stream
      stream.read
    end
  end
end
```

**`lib/exports/json_export.rb`**:
```ruby
module Exports
  module JsonExport
    def generate_json
      data = records.map do |record|
        columns.each_with_object({}) do |col, hash|
          hash[col[:key]] = col[:value].call(record)
        end
      end
      { export_name: export_name, exported_at: Time.zone.now.iso8601,
        filters: options.except(:format), record_count: data.size, data: data }.to_json
    end
  end
end
```

**`lib/exports/pdf_export.rb`** — wraps existing `Printable` subclasses or generates simple table PDFs:
```ruby
module Exports
  module PdfExport
    def generate_pdf
      # Default: simple table PDF using Prawn
      # Subclasses can override for custom layouts (e.g., ShippingExport delegates to OroshiOrderDocument)
      pdf = Printable.new
      pdf.text export_name, size: 14, style: :bold
      pdf.move_down 10
      table_data = [columns.map { |c| c[:header] }]
      records.each { |r| table_data << columns.map { |c| c[:value].call(r).to_s } }
      pdf.table(table_data, header: true, width: pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = "f0f0f0"
        cells.border_width = 0.5
        cells.size = 7
      end
      pdf.render
    end
  end
end
```

### Step 4: Create data-specific export classes

Each export class defines `load_data`, `columns`, and `export_name`. Columns use Japanese headers matching the UI.

#### **`lib/exports/orders_export.rb`** — Order List

Columns: 出荷日, 到着日, 買い手, 商品, バリエーション, 数量, ケース数, フレート数, 単価, 売上, 経費, 利益, 配送方法, カテゴリ, ノート

- `load_data`: `Oroshi::Order.non_template.where(shipping_date: date_range).includes(:buyer, :product_variation, :product, :shipping_method, :shipping_organization, :shipping_receptacle, :order_categories)`
- Applies all filters via `apply_order_filters`
- Date support: single date (current view) or date range

#### **`lib/exports/revenue_export.rb`** — Profit Calculation

Columns: 日付, 商品, バリエーション, 買い手, 数量, 単価, 売上, 手数料後売上, 材料費, 配送費, 調整, 経費合計, 利益

- `load_data`: Same as orders but groups by product → product_variation with totals
- Summary rows: revenue subtotal, expenses subtotal, buyer daily costs, shipping method daily costs, net profit
- For XLSX: adds a summary sheet with daily totals and formulas
- For CSV/JSON: appends summary rows at the end

#### **`lib/exports/production_export.rb`** — Factory Floor

Columns: 製造日, 出荷日, 商品, バリエーション, 製造ゾーン, 依頼数量, 完了数量, 残数量, 在庫数量, ステータス

- `load_data`: Production requests + product inventories for the date range (±1 day buffer like the production dashboard)
- Includes inventory quantities and production zone assignments

#### **`lib/exports/inventory_export.rb`** — Inventory List

Columns: 商品, バリエーション, 製造日, 賞味期限, 在庫数量, フレート数, 未出荷注文数, 差分

- `load_data`: `Oroshi::ProductInventory` with associated product variations and pending orders
- Shows current stock vs outstanding orders

#### **`lib/exports/supply_export.rb`** — Daily Intake

Columns: 供給日, 仕入先組織, 仕入先, 原料種類, バリエーション, 数量, 単位, 単価, 金額, 受入時間

- `load_data`: `Oroshi::Supply.with_quantity` for the given date/range
- Includes supplier organization and supply type information

#### **`lib/exports/shipping_export.rb`** — Shipping Chart

- For **PDF**: delegates to existing `OroshiOrderDocument` (preserves current B4 landscape layout)
- For **CSV/XLSX/JSON**: flattened order data grouped by shipping organization with freight quantities

### Step 5: Create unified `Oroshi::ExportJob`

```ruby
# app/jobs/oroshi/export_job.rb
class Oroshi::ExportJob < ApplicationJob
  queue_as :default

  def perform(export_class, format, message_id, options = {})
    message = Message.find(message_id)
    exporter = export_class.constantize.new(options)
    content = exporter.generate(format)
    io = StringIO.new(content)
    message.stored_file.attach(
      io: io,
      content_type: exporter.content_type(format),
      filename: exporter.filename(format)
    )
    message.update(state: true, message: I18n.t("oroshi.exports.completed"))
    GC.start if format == "pdf"
  rescue => e
    message&.update(state: false, message: I18n.t("oroshi.exports.failed", error: e.message))
    raise
  end
end
```

This replaces the pattern of having one job per document type. The existing `OrderDocumentJob` and `SupplyCheckJob` remain untouched for backward compatibility — only new exports use `ExportJob`.

### Step 6: Create `Oroshi::ExportsController`

```ruby
# app/controllers/oroshi/exports_controller.rb
class Oroshi::ExportsController < Oroshi::ApplicationController
  before_action :authorize_export

  # POST /oroshi/exports
  def create
    message = create_export_message
    Oroshi::ExportJob.perform_later(
      export_class_name,
      params[:format_type],
      message.id,
      export_options
    )
    head :ok
  end

  private

  def export_class_name
    # Maps params[:export_type] to class name
    {
      "orders" => "Exports::OrdersExport",
      "revenue" => "Exports::RevenueExport",
      "production" => "Exports::ProductionExport",
      "inventory" => "Exports::InventoryExport",
      "supply" => "Exports::SupplyExport",
      "shipping" => "Exports::ShippingExport"
    }.fetch(params[:export_type])
  end

  def export_options
    params.permit(:date, :start_date, :end_date,
                  buyer_ids: [], shipping_method_ids: [],
                  order_category_ids: [], buyer_category_ids: [])
          .to_h
          .compact_blank
  end

  def create_export_message
    Message.create!(
      user: current_user.id,
      model: "oroshi_export",
      state: nil,
      message: I18n.t("oroshi.exports.processing"),
      data: {
        export_type: params[:export_type],
        format: params[:format_type],
        expiration: 1.day.from_now
      }
    )
  end

  def authorize_export
    authorize :export, :create?
  end
end
```

### Step 7: Add routes

```ruby
# In config/routes.rb, add inside Oroshi::Engine.routes.draw:
resources :exports, only: [:create]
```

### Step 8: Create Pundit policy

```ruby
# app/policies/oroshi/export_policy.rb
class Oroshi::ExportPolicy < Oroshi::ApplicationPolicy
  def create?
    # Same authorization as viewing the data being exported
    user.present?
  end
end
```

### Step 9: Create export button partial

A reusable dropdown button that can be placed on any dashboard tab:

```erb
<%# app/views/oroshi/exports/_export_button.html.erb %>
<%# locals: export_type, date, additional_params: {} %>
<div class="dropdown d-inline-block">
  <button class="btn btn-sm btn-outline-secondary dropdown-toggle"
          type="button" data-bs-toggle="dropdown">
    <%= t('oroshi.exports.button') %>
  </button>
  <ul class="dropdown-menu">
    <% %w[csv xlsx pdf json].each do |fmt| %>
      <li>
        <%= button_to exports_path, method: :post,
            params: { export_type: export_type, format_type: fmt, date: date }.merge(additional_params),
            class: "dropdown-item", data: { turbo_prefetch: false } do %>
          <%= t("oroshi.exports.formats.#{fmt}") %>
        <% end %>
      </li>
    <% end %>
  </ul>
</div>
```

### Step 10: Create date range export form

A modal form for exporting a custom date range (in addition to "current view" exports):

```erb
<%# app/views/oroshi/exports/_date_range_export.html.erb %>
<%# locals: export_type %>
<dialog id="date_range_export_dialog">
  <%= form_with url: exports_path, method: :post do |f| %>
    <%= f.hidden_field :export_type, value: export_type %>
    <div class="mb-3">
      <%= f.label :start_date, t('oroshi.exports.start_date') %>
      <%= f.date_field :start_date, value: 1.month.ago.to_date, class: "form-control" %>
    </div>
    <div class="mb-3">
      <%= f.label :end_date, t('oroshi.exports.end_date') %>
      <%= f.date_field :end_date, value: Time.zone.today, class: "form-control" %>
    </div>
    <div class="mb-3">
      <%= f.label :format_type, t('oroshi.exports.format') %>
      <%= f.select :format_type, export_format_options, {}, class: "form-select" %>
    </div>
    <%= f.submit t('oroshi.exports.download'), class: "btn btn-primary" %>
  <% end %>
</dialog>
```

### Step 11: Add i18n translations

```yaml
# config/locales/exports.ja.yml
ja:
  oroshi:
    exports:
      button: "エクスポート"
      processing: "エクスポート処理中…"
      completed: "エクスポート完了"
      failed: "エクスポートに失敗しました: %{error}"
      download: "ダウンロード"
      start_date: "開始日"
      end_date: "終了日"
      format: "形式"
      date_range: "期間指定エクスポート"
      formats:
        csv: "CSV"
        xlsx: "Excel (XLSX)"
        pdf: "PDF"
        json: "JSON"
      types:
        orders: "注文一覧"
        revenue: "売上・利益"
        production: "製造・工場"
        inventory: "在庫一覧"
        supply: "入荷一覧"
        shipping: "出荷表"
```

### Step 12: Integrate export buttons into existing views

Add the `_export_button` partial to each dashboard tab view:

1. **Order List** (`_orders.html.erb`) — `export_type: "orders"`
2. **Revenue** (`_revenue.html.erb`) — `export_type: "revenue"`
3. **Production** (`_production.html.erb`) — `export_type: "production"`
4. **Supply Usage** (`_supply_usage.html.erb`) — `export_type: "inventory"`
5. **Shipping** (`_shipping.html.erb`) — `export_type: "shipping"`
6. **Supply Dates** (supply_dates show) — `export_type: "supply"`

Each button passes the current `@date` and any active filter params as `additional_params`.

### Step 13: Write tests

Create test files following existing patterns:

- `test/lib/exports/base_export_test.rb` — column definition, format dispatch
- `test/lib/exports/orders_export_test.rb` — data loading, filtering, CSV/XLSX/JSON output
- `test/lib/exports/revenue_export_test.rb` — profit calculation accuracy
- `test/lib/exports/production_export_test.rb` — production request data
- `test/lib/exports/inventory_export_test.rb` — inventory quantities
- `test/lib/exports/supply_export_test.rb` — supply data
- `test/jobs/oroshi/export_job_test.rb` — job execution, message updates, error handling
- `test/controllers/oroshi/exports_controller_test.rb` — authorization, parameter handling

---

## Edge Cases & Considerations

### Data Integrity
- **Empty data**: Export gracefully with headers only (no crash on zero records)
- **Large datasets**: Date range exports could be large — XLSX has ~1M row limit, CSV streams fine, JSON may need pagination consideration (but for typical wholesale volumes this is unlikely to be hit)
- **Concurrent exports**: Multiple users can export simultaneously; each gets their own `Message` record

### Encoding
- **CSV**: Use `"\xEF\xBB\xBF"` BOM prefix for proper Excel UTF-8 handling of Japanese characters
- **XLSX**: Native Unicode support via caxlsx
- **JSON**: UTF-8 by default

### Filters
- "Current view" exports respect all active dashboard filters (buyer, shipping method, order category, buyer category)
- "Date range" exports only accept date range + optional filters
- Filters are serialized into `Message.data` for audit trail

### Backward Compatibility
- Existing `OrderDocumentJob`, `InvoiceJob`, `SupplyCheckJob` remain untouched
- Existing shipping chart PDF generation continues to work exactly as before
- `ShippingExport` for PDF format delegates to `OroshiOrderDocument` to preserve the established B4 landscape layout

### Security
- All exports go through Pundit authorization (`ExportPolicy`)
- Export options are permitted via strong parameters
- Files are served through ActiveStorage's signed URLs (existing pattern)
- No user-supplied strings used in filenames without sanitization

### Performance
- All formats run async via Solid Queue — no request blocking
- `GC.start` after PDF generation (matching existing pattern)
- Eager loading (`.includes()`) on all queries to prevent N+1
- Date range exports with many records: XLSX uses streaming where possible

### Japanese-First
- All column headers, UI labels, and status messages in Japanese
- Currency formatting with `¥` symbol and comma separators
- Date formatting using Japanese locale (`%Y年%m月%d日`)
- Translations in `config/locales/exports.ja.yml`

---

## File Summary

| File | Action | Description |
|------|--------|-------------|
| `Gemfile` | EDIT | Add `gem "caxlsx"` |
| `lib/exports/base_export.rb` | CREATE | Abstract base class |
| `lib/exports/csv_export.rb` | CREATE | CSV generation mixin |
| `lib/exports/xlsx_export.rb` | CREATE | XLSX generation mixin |
| `lib/exports/json_export.rb` | CREATE | JSON generation mixin |
| `lib/exports/pdf_export.rb` | CREATE | PDF generation mixin |
| `lib/exports/orders_export.rb` | CREATE | Order list export |
| `lib/exports/revenue_export.rb` | CREATE | Revenue/profit export |
| `lib/exports/production_export.rb` | CREATE | Production/factory export |
| `lib/exports/inventory_export.rb` | CREATE | Inventory export |
| `lib/exports/supply_export.rb` | CREATE | Daily supply intake export |
| `lib/exports/shipping_export.rb` | CREATE | Shipping data export |
| `app/jobs/oroshi/export_job.rb` | CREATE | Unified export job |
| `app/controllers/oroshi/exports_controller.rb` | CREATE | Export request handler |
| `app/policies/oroshi/export_policy.rb` | CREATE | Pundit policy |
| `app/views/oroshi/exports/_export_button.html.erb` | CREATE | Reusable dropdown button |
| `app/views/oroshi/exports/_date_range_export.html.erb` | CREATE | Date range modal |
| `config/locales/exports.ja.yml` | CREATE | Japanese translations |
| `config/routes.rb` | EDIT | Add export route |
| `app/views/oroshi/orders/dashboard/_orders.html.erb` | EDIT | Add export button |
| `app/views/oroshi/orders/dashboard/_revenue.html.erb` | EDIT | Add export button |
| `app/views/oroshi/orders/dashboard/_production.html.erb` | EDIT | Add export button |
| `app/views/oroshi/orders/dashboard/_supply_usage.html.erb` | EDIT | Add export button |
| `app/views/oroshi/orders/dashboard/_shipping.html.erb` | EDIT | Add export button |
| `test/lib/exports/*_test.rb` | CREATE | Export unit tests |
| `test/jobs/oroshi/export_job_test.rb` | CREATE | Job test |
| `test/controllers/oroshi/exports_controller_test.rb` | CREATE | Controller test |

**Total: ~12 new files, ~8 edits to existing files, plus ~7 test files**

---

## Implementation Order

1. Gem dependency + base export classes (Steps 1-3)
2. Data-specific export classes (Step 4)
3. Job + Controller + Routes + Policy (Steps 5-8)
4. UI integration — button partial + date range form (Steps 9-10)
5. i18n translations (Step 11)
6. Wire buttons into existing views (Step 12)
7. Tests (Step 13)
