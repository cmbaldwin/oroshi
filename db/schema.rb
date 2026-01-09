# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_09_061454) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "key_name", null: false
    t.text "notes"
    t.string "service", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.text "value"
    t.index ["expires_at"], name: "index_credentials_on_expires_at"
    t.index ["service", "key_name", "user_id"], name: "index_credentials_on_service_key_user", unique: true
    t.index ["status"], name: "index_credentials_on_status"
    t.index ["user_id"], name: "index_credentials_on_user_id"
  end

  create_table "oroshi_addresses", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "address1"
    t.string "address2"
    t.bigint "addressable_id", null: false
    t.string "addressable_type", null: false
    t.string "alternative_phone"
    t.string "city"
    t.string "company"
    t.integer "country_id"
    t.datetime "created_at", null: false
    t.boolean "default", default: false
    t.string "name"
    t.string "phone"
    t.string "postal_code"
    t.integer "subregion_id"
    t.datetime "updated_at", null: false
    t.index ["addressable_type", "addressable_id"], name: "index_oroshi_addresses_on_addressable"
  end

  create_table "oroshi_buyer_categories", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "symbol"
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_buyers", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "associated_system_id"
    t.boolean "brokerage", default: true
    t.string "color"
    t.decimal "commission_percentage", null: false
    t.datetime "created_at", null: false
    t.float "daily_cost", null: false
    t.string "daily_cost_notes"
    t.integer "entity_type", null: false
    t.string "fax"
    t.string "handle", null: false
    t.float "handling_cost", null: false
    t.string "handling_cost_notes"
    t.string "name", null: false
    t.float "optional_cost", null: false
    t.string "optional_cost_notes"
    t.string "representative_phone"
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_buyers_shipping_methods", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.datetime "created_at", null: false
    t.bigint "shipping_method_id", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_oroshi_buyers_shipping_methods_on_buyer_id"
    t.index ["shipping_method_id"], name: "index_oroshi_buyers_shipping_methods_on_shipping_method_id"
  end

  create_table "oroshi_invoice_supplier_organizations", force: :cascade do |t|
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.jsonb "passwords", default: {}
    t.datetime "sent_at"
    t.bigint "supplier_organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_oroshi_invoice_supplier_organizations_on_invoice_id"
    t.index ["supplier_organization_id"], name: "idx_on_supplier_organization_id_85375e363b"
  end

  create_table "oroshi_invoice_supply_dates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.bigint "supply_date_id", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_oroshi_invoice_supply_dates_on_invoice_id"
    t.index ["supply_date_id"], name: "index_oroshi_invoice_supply_dates_on_supply_date_id"
  end

  create_table "oroshi_invoices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date"
    t.integer "invoice_layout"
    t.datetime "send_at"
    t.boolean "send_email"
    t.datetime "sent_at"
    t.date "start_date"
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_material_categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_materials", force: :cascade do |t|
    t.boolean "active", default: true
    t.float "cost", null: false
    t.datetime "created_at", null: false
    t.bigint "material_category_id", null: false
    t.string "name", null: false
    t.integer "per", null: false
    t.datetime "updated_at", null: false
    t.index ["material_category_id"], name: "index_oroshi_materials_on_material_category_id"
  end

  create_table "oroshi_onboarding_progresses", force: :cascade do |t|
    t.datetime "checklist_dismissed_at"
    t.datetime "completed_at"
    t.jsonb "completed_steps", default: []
    t.datetime "created_at", null: false
    t.string "current_step"
    t.datetime "skipped_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_oroshi_onboarding_progresses_on_user_id"
  end

  create_table "oroshi_order_categories", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_order_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "identifier"
    t.text "notes"
    t.bigint "order_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_oroshi_order_templates_on_order_id"
  end

  create_table "oroshi_orders", force: :cascade do |t|
    t.boolean "add_buyer_optional_cost", default: false
    t.float "adjustment", default: 0.0, null: false
    t.date "arrival_date"
    t.boolean "bundled_shipping_receptacle", default: false
    t.bigint "bundled_with_order_id"
    t.bigint "buyer_id", null: false
    t.datetime "created_at", null: false
    t.integer "freight_quantity", default: 0, null: false
    t.integer "item_quantity", default: 0, null: false
    t.float "materials_cost", default: 0.0, null: false
    t.string "note"
    t.bigint "payment_receipt_id"
    t.bigint "product_inventory_id", null: false
    t.bigint "product_variation_id", null: false
    t.integer "receptacle_quantity", default: 0, null: false
    t.float "sale_price_per_item", default: 0.0, null: false
    t.float "shipping_cost", default: 0.0, null: false
    t.date "shipping_date"
    t.bigint "shipping_method_id", null: false
    t.bigint "shipping_receptacle_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["bundled_with_order_id"], name: "index_oroshi_orders_on_bundled_with_order_id"
    t.index ["buyer_id"], name: "index_oroshi_orders_on_buyer_id"
    t.index ["payment_receipt_id"], name: "index_oroshi_orders_on_payment_receipt_id"
    t.index ["product_inventory_id"], name: "index_oroshi_orders_on_product_inventory_id"
    t.index ["product_variation_id"], name: "index_oroshi_orders_on_product_variation_id"
    t.index ["shipping_method_id"], name: "index_oroshi_orders_on_shipping_method_id"
    t.index ["shipping_receptacle_id"], name: "index_oroshi_orders_on_shipping_receptacle_id"
  end

  create_table "oroshi_packagings", force: :cascade do |t|
    t.boolean "active", default: true
    t.float "cost", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "product_id"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_oroshi_packagings_on_product_id"
  end

  create_table "oroshi_payment_receipt_adjustment_types", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_payment_receipt_adjustments", force: :cascade do |t|
    t.decimal "amount", default: "0.0", null: false
    t.datetime "created_at", null: false
    t.bigint "payment_receipt_adjustment_type_id", null: false
    t.bigint "payment_receipt_id", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_receipt_adjustment_type_id"], name: "idx_on_payment_receipt_adjustment_type_id_9bd7deeb86"
    t.index ["payment_receipt_id"], name: "index_oroshi_payment_receipt_adjustments_on_payment_receipt_id"
  end

  create_table "oroshi_payment_receipts", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.datetime "created_at", null: false
    t.date "deadline_date", null: false
    t.date "deposit_date", null: false
    t.decimal "deposit_total", default: "0.0", null: false
    t.date "issue_date", null: false
    t.string "note"
    t.decimal "total", default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_oroshi_payment_receipts_on_buyer_id"
  end

  create_table "oroshi_product_inventories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expiration_date", null: false
    t.date "manufacture_date", null: false
    t.bigint "product_variation_id", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["product_variation_id"], name: "index_oroshi_product_inventories_on_product_variation_id"
  end

  create_table "oroshi_product_materials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "material_id", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["material_id"], name: "index_oroshi_product_materials_on_material_id"
    t.index ["product_id"], name: "index_oroshi_product_materials_on_product_id"
  end

  create_table "oroshi_product_variation_packagings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "packaging_id", null: false
    t.bigint "product_variation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["packaging_id"], name: "index_oroshi_product_variation_packagings_on_packaging_id"
    t.index ["product_variation_id"], name: "idx_on_product_variation_id_9188fea723"
  end

  create_table "oroshi_product_variation_production_zones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_variation_id", null: false
    t.bigint "production_zone_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_variation_id"], name: "idx_on_product_variation_id_d080048cfb"
    t.index ["production_zone_id"], name: "idx_on_production_zone_id_cc4cc5a5ab"
  end

  create_table "oroshi_product_variation_supply_type_variations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_variation_id", null: false
    t.bigint "supply_type_variation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_variation_id"], name: "idx_on_product_variation_id_0daf74b3b8"
    t.index ["supply_type_variation_id"], name: "idx_on_supply_type_variation_id_8cd5e1bc89"
  end

  create_table "oroshi_product_variations", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.integer "default_per_box"
    t.bigint "default_shipping_receptacle_id"
    t.string "handle", null: false
    t.string "name", null: false
    t.integer "primary_content_country_id"
    t.integer "primary_content_subregion_id"
    t.float "primary_content_volume", null: false
    t.bigint "product_id", null: false
    t.integer "shelf_life"
    t.decimal "spacing_volume_adjustment", precision: 5, scale: 2, default: "1.0"
    t.datetime "updated_at", null: false
    t.index ["default_shipping_receptacle_id"], name: "idx_on_default_shipping_receptacle_id_8db7516e01"
    t.index ["product_id"], name: "index_oroshi_product_variations_on_product_id"
  end

  create_table "oroshi_production_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "fulfilled_quantity", default: 0, null: false
    t.bigint "product_inventory_id"
    t.bigint "product_variation_id", null: false
    t.bigint "production_zone_id", null: false
    t.integer "request_quantity", null: false
    t.bigint "shipping_receptacle_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["product_inventory_id"], name: "index_oroshi_production_requests_on_product_inventory_id"
    t.index ["product_variation_id"], name: "index_oroshi_production_requests_on_product_variation_id"
    t.index ["production_zone_id"], name: "index_oroshi_production_requests_on_production_zone_id"
    t.index ["shipping_receptacle_id"], name: "index_oroshi_production_requests_on_shipping_receptacle_id"
  end

  create_table "oroshi_production_zones", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_products", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.decimal "exterior_depth"
    t.decimal "exterior_height"
    t.decimal "exterior_width"
    t.string "name", null: false
    t.integer "position"
    t.decimal "supply_loss_adjustment", precision: 5, scale: 2, default: "1.0"
    t.bigint "supply_type_id", null: false
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0"
    t.string "units", null: false
    t.datetime "updated_at", null: false
    t.index ["supply_type_id"], name: "index_oroshi_products_on_supply_type_id"
  end

  create_table "oroshi_shipping_methods", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.float "daily_cost", default: 0.0, null: false
    t.string "departure_times", default: [], array: true
    t.string "handle", null: false
    t.string "name", null: false
    t.float "per_freight_unit_cost", default: 0.0, null: false
    t.float "per_shipping_receptacle_cost", default: 0.0, null: false
    t.bigint "shipping_organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shipping_organization_id"], name: "index_oroshi_shipping_methods_on_shipping_organization_id"
  end

  create_table "oroshi_shipping_organizations", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "handle", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_shipping_receptacles", force: :cascade do |t|
    t.boolean "active", default: true
    t.float "cost", null: false
    t.datetime "created_at", null: false
    t.integer "default_freight_bundle_quantity", default: 1
    t.decimal "exterior_depth"
    t.decimal "exterior_height"
    t.decimal "exterior_width"
    t.string "handle", null: false
    t.decimal "interior_depth"
    t.decimal "interior_height"
    t.decimal "interior_width"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_supplier_organizations", force: :cascade do |t|
    t.boolean "active"
    t.integer "country_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "entity_name", null: false
    t.integer "entity_type", null: false
    t.string "fax"
    t.boolean "free_entry", default: false
    t.string "honorific_title"
    t.string "invoice_name"
    t.string "invoice_number"
    t.string "micro_region"
    t.string "phone"
    t.integer "subregion_id", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_supplier_organizations_oroshi_supply_reception_times", force: :cascade do |t|
    t.bigint "supplier_organization_id", null: false
    t.bigint "supply_reception_time_id", null: false
    t.index ["supplier_organization_id"], name: "idx_on_supplier_organization_id_cecc289244"
    t.index ["supply_reception_time_id"], name: "idx_on_supply_reception_time_id_bd1921216d"
  end

  create_table "oroshi_suppliers", force: :cascade do |t|
    t.boolean "active"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "honorific_title"
    t.string "invoice_name"
    t.string "invoice_number"
    t.string "phone"
    t.text "representatives", default: [], array: true
    t.string "short_name"
    t.integer "supplier_number"
    t.bigint "supplier_organization_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["supplier_organization_id"], name: "index_oroshi_suppliers_on_supplier_organization_id"
  end

  create_table "oroshi_suppliers_oroshi_supply_type_variations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "supplier_id", null: false
    t.bigint "supply_type_variation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "idx_on_supplier_id_78ea5376f0"
    t.index ["supply_type_variation_id"], name: "idx_on_supply_type_variation_id_ed73826397"
  end

  create_table "oroshi_supplies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "entry_index"
    t.boolean "locked", default: false
    t.float "price", default: 0.0, null: false
    t.float "quantity", default: 0.0, null: false
    t.bigint "supplier_id", null: false
    t.bigint "supply_date_id", null: false
    t.bigint "supply_reception_time_id", null: false
    t.bigint "supply_type_variation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "index_oroshi_supplies_on_supplier_id"
    t.index ["supply_date_id"], name: "index_oroshi_supplies_on_supply_date_id"
    t.index ["supply_reception_time_id"], name: "index_oroshi_supplies_on_supply_reception_time_id"
    t.index ["supply_type_variation_id"], name: "index_oroshi_supplies_on_supply_type_variation_id"
  end

  create_table "oroshi_supply_date_supplier_organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "supplier_organization_id", null: false
    t.bigint "supply_date_id", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_organization_id", "supply_date_id"], name: "index_supplier_organizations_supply_dates_on_ids"
    t.index ["supplier_organization_id"], name: "idx_on_supplier_organization_id_a9291c6a52"
    t.index ["supply_date_id", "supplier_organization_id"], name: "index_supply_date_supplier_organizations_on_ids", unique: true
    t.index ["supply_date_id"], name: "idx_on_supply_date_id_c5793d363e"
  end

  create_table "oroshi_supply_date_suppliers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "supplier_id", null: false
    t.bigint "supply_date_id", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id", "supply_date_id"], name: "index_suppliers_supply_dates_on_ids"
    t.index ["supplier_id"], name: "index_oroshi_supply_date_suppliers_on_supplier_id"
    t.index ["supply_date_id", "supplier_id"], name: "index_supply_date_suppliers_on_ids", unique: true
    t.index ["supply_date_id"], name: "index_oroshi_supply_date_suppliers_on_supply_date_id"
  end

  create_table "oroshi_supply_date_supply_type_variations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "supply_date_id", null: false
    t.bigint "supply_type_variation_id", null: false
    t.integer "total", default: 0
    t.datetime "updated_at", null: false
    t.index ["supply_date_id", "supply_type_variation_id"], name: "index_supply_date_supply_type_variations_on_ids", unique: true
    t.index ["supply_date_id"], name: "idx_on_supply_date_id_2fa23a9b0e"
    t.index ["supply_type_variation_id", "supply_date_id"], name: "index_supply_type_variations_supply_dates_on_ids"
    t.index ["supply_type_variation_id"], name: "idx_on_supply_type_variation_id_87a1480921"
  end

  create_table "oroshi_supply_date_supply_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "supply_date_id", null: false
    t.bigint "supply_type_id", null: false
    t.integer "total", default: 0
    t.datetime "updated_at", null: false
    t.index ["supply_date_id", "supply_type_id"], name: "index_supply_date_supply_types_on_ids", unique: true
    t.index ["supply_date_id"], name: "index_oroshi_supply_date_supply_types_on_supply_date_id"
    t.index ["supply_type_id", "supply_date_id"], name: "index_supply_types_supply_dates_on_ids"
    t.index ["supply_type_id"], name: "index_oroshi_supply_date_supply_types_on_supply_type_id"
  end

  create_table "oroshi_supply_dates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.jsonb "totals", default: {}
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_oroshi_supply_dates_on_date", unique: true
  end

  create_table "oroshi_supply_reception_times", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "hour"
    t.string "time_qualifier"
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_supply_type_variations", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.integer "default_container_count"
    t.string "handle"
    t.string "name"
    t.bigint "supply_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["supply_type_id"], name: "index_oroshi_supply_type_variations_on_supply_type_id"
  end

  create_table "oroshi_supply_types", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "handle"
    t.boolean "liquid", default: false
    t.string "name"
    t.integer "position"
    t.string "units"
    t.datetime "updated_at", null: false
  end

  create_table "service_configurations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "enabled", default: false, null: false
    t.string "service", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_service_configurations_on_enabled"
    t.index ["service"], name: "index_service_configurations_on_service", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.jsonb "settings"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.boolean "approved", default: false, null: false
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.text "data"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "role"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "username"
    t.index ["approved"], name: "index_users_on_approved"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "credentials", "users"
  add_foreign_key "oroshi_buyers_shipping_methods", "oroshi_buyers", column: "buyer_id"
  add_foreign_key "oroshi_buyers_shipping_methods", "oroshi_shipping_methods", column: "shipping_method_id"
  add_foreign_key "oroshi_invoice_supplier_organizations", "oroshi_invoices", column: "invoice_id", on_delete: :cascade
  add_foreign_key "oroshi_invoice_supplier_organizations", "oroshi_supplier_organizations", column: "supplier_organization_id"
  add_foreign_key "oroshi_invoice_supply_dates", "oroshi_invoices", column: "invoice_id", on_delete: :cascade
  add_foreign_key "oroshi_invoice_supply_dates", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_materials", "oroshi_material_categories", column: "material_category_id"
  add_foreign_key "oroshi_onboarding_progresses", "users"
  add_foreign_key "oroshi_order_templates", "oroshi_orders", column: "order_id"
  add_foreign_key "oroshi_orders", "oroshi_buyers", column: "buyer_id"
  add_foreign_key "oroshi_orders", "oroshi_orders", column: "bundled_with_order_id"
  add_foreign_key "oroshi_orders", "oroshi_payment_receipts", column: "payment_receipt_id"
  add_foreign_key "oroshi_orders", "oroshi_product_inventories", column: "product_inventory_id"
  add_foreign_key "oroshi_orders", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_orders", "oroshi_shipping_methods", column: "shipping_method_id"
  add_foreign_key "oroshi_orders", "oroshi_shipping_receptacles", column: "shipping_receptacle_id"
  add_foreign_key "oroshi_packagings", "oroshi_products", column: "product_id"
  add_foreign_key "oroshi_payment_receipt_adjustments", "oroshi_payment_receipt_adjustment_types", column: "payment_receipt_adjustment_type_id"
  add_foreign_key "oroshi_payment_receipt_adjustments", "oroshi_payment_receipts", column: "payment_receipt_id"
  add_foreign_key "oroshi_payment_receipts", "oroshi_buyers", column: "buyer_id"
  add_foreign_key "oroshi_product_inventories", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_product_materials", "oroshi_materials", column: "material_id"
  add_foreign_key "oroshi_product_materials", "oroshi_products", column: "product_id"
  add_foreign_key "oroshi_product_variation_packagings", "oroshi_packagings", column: "packaging_id"
  add_foreign_key "oroshi_product_variation_packagings", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_product_variation_production_zones", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_product_variation_production_zones", "oroshi_production_zones", column: "production_zone_id"
  add_foreign_key "oroshi_product_variation_supply_type_variations", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_product_variation_supply_type_variations", "oroshi_supply_type_variations", column: "supply_type_variation_id"
  add_foreign_key "oroshi_product_variations", "oroshi_products", column: "product_id"
  add_foreign_key "oroshi_product_variations", "oroshi_shipping_receptacles", column: "default_shipping_receptacle_id"
  add_foreign_key "oroshi_production_requests", "oroshi_product_inventories", column: "product_inventory_id"
  add_foreign_key "oroshi_production_requests", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_production_requests", "oroshi_production_zones", column: "production_zone_id"
  add_foreign_key "oroshi_production_requests", "oroshi_shipping_receptacles", column: "shipping_receptacle_id"
  add_foreign_key "oroshi_products", "oroshi_supply_types", column: "supply_type_id"
  add_foreign_key "oroshi_shipping_methods", "oroshi_shipping_organizations", column: "shipping_organization_id"
  add_foreign_key "oroshi_supplier_organizations_oroshi_supply_reception_times", "oroshi_supplier_organizations", column: "supplier_organization_id"
  add_foreign_key "oroshi_supplier_organizations_oroshi_supply_reception_times", "oroshi_supply_reception_times", column: "supply_reception_time_id"
  add_foreign_key "oroshi_suppliers", "oroshi_supplier_organizations", column: "supplier_organization_id"
  add_foreign_key "oroshi_suppliers_oroshi_supply_type_variations", "oroshi_suppliers", column: "supplier_id"
  add_foreign_key "oroshi_suppliers_oroshi_supply_type_variations", "oroshi_supply_type_variations", column: "supply_type_variation_id"
  add_foreign_key "oroshi_supplies", "oroshi_suppliers", column: "supplier_id"
  add_foreign_key "oroshi_supplies", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supplies", "oroshi_supply_reception_times", column: "supply_reception_time_id"
  add_foreign_key "oroshi_supplies", "oroshi_supply_type_variations", column: "supply_type_variation_id"
  add_foreign_key "oroshi_supply_date_supplier_organizations", "oroshi_supplier_organizations", column: "supplier_organization_id"
  add_foreign_key "oroshi_supply_date_supplier_organizations", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supply_date_suppliers", "oroshi_suppliers", column: "supplier_id"
  add_foreign_key "oroshi_supply_date_suppliers", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supply_date_supply_type_variations", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supply_date_supply_type_variations", "oroshi_supply_type_variations", column: "supply_type_variation_id"
  add_foreign_key "oroshi_supply_date_supply_types", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supply_date_supply_types", "oroshi_supply_types", column: "supply_type_id"
  add_foreign_key "oroshi_supply_type_variations", "oroshi_supply_types", column: "supply_type_id"
end
