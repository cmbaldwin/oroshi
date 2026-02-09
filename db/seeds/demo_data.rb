# frozen_string_literal: true

# Comprehensive demo data for Oroshi sandbox
# This file creates realistic example data for all major models
# Run with: DEMO_DATA=true bin/rails db:seed

unless ENV["DEMO_DATA"] == "true"
  puts "Skipping demo data: set DEMO_DATA=true to load (current: #{ENV['DEMO_DATA']})."
  return
end

puts "== Seeding comprehensive demo data =="

# ============================================================================
# FOUNDATION: Company & System Configuration
# ============================================================================

puts "→ Company settings..."
Setting.find_or_initialize_by(name: "oroshi_company_settings")
       .update!(settings: {
         name: "株式会社オロシサーモン",
         postal_code: "060-0042",
         address: "北海道札幌市中央区大通西1-1-1 オロシビル5F",
         phone: "011-555-0123",
         fax: "011-555-0124",
         mail: "info@oroshi-salmon.jp",
         web: "https://www.oroshi-salmon.jp",
         invoice_number: "T1234567890123"
       })

# ============================================================================
# SUPPLY CHAIN: Reception Times & Organizations
# ============================================================================

puts "→ Supply reception times..."
morning = Oroshi::SupplyReceptionTime.find_or_create_by!(time_qualifier: "morning", hour: 9)
afternoon = Oroshi::SupplyReceptionTime.find_or_create_by!(time_qualifier: "afternoon", hour: 14)
evening = Oroshi::SupplyReceptionTime.find_or_create_by!(time_qualifier: "evening", hour: 17)

puts "→ Supplier organizations..."
hokkaido_coop = Oroshi::SupplierOrganization.find_or_initialize_by(entity_name: "北海水産協同組合")
hokkaido_coop.assign_attributes(
  entity_type: :company,
  country_id: 392, # Japan
  subregion_id: 1, # Hokkaido
  micro_region: "札幌市",
  invoice_number: "T9876543210987",
  fax: "011-222-3333",
  free_entry: false,
  active: true
)
hokkaido_coop.supply_reception_times = [ morning, afternoon ]
hokkaido_coop.save!

aomori_coop = Oroshi::SupplierOrganization.find_or_initialize_by(entity_name: "青森県漁業協同組合連合会")
aomori_coop.assign_attributes(
  entity_type: :company,
  country_id: 392,
  subregion_id: 2, # Aomori
  micro_region: "青森市",
  invoice_number: "T1234567891234",
  fax: "017-777-8888",
  free_entry: false,
  active: true
)
aomori_coop.supply_reception_times = [ morning, evening ]
aomori_coop.save!

puts "→ Suppliers..."
sapporo_salmon = Oroshi::Supplier.find_or_initialize_by(company_name: "札幌サーモン株式会社")
sapporo_salmon.assign_attributes(
  supplier_number: 1001,
  representatives: [ "山田 太郎", "佐藤 花子" ],
  invoice_number: "T1111111111111",
  supplier_organization: hokkaido_coop,
  active: true
)
sapporo_salmon.save!

hakodate_fish = Oroshi::Supplier.find_or_initialize_by(company_name: "函館水産株式会社")
hakodate_fish.assign_attributes(
  supplier_number: 1002,
  representatives: [ "鈴木 次郎" ],
  invoice_number: "T2222222222222",
  supplier_organization: hokkaido_coop,
  active: true
)
hakodate_fish.save!

aomori_seafood = Oroshi::Supplier.find_or_initialize_by(company_name: "青森海産物株式会社")
aomori_seafood.assign_attributes(
  supplier_number: 2001,
  representatives: [ "田中 三郎" ],
  invoice_number: "T3333333333333",
  supplier_organization: aomori_coop,
  active: true
)
aomori_seafood.save!

# ============================================================================
# SUPPLY TYPES & VARIATIONS
# ============================================================================

puts "→ Supply types..."
salmon = Oroshi::SupplyType.find_or_initialize_by(handle: "salmon")
salmon.assign_attributes(name: "鮭", units: "kg", liquid: false, active: true)
salmon.save!

tuna = Oroshi::SupplyType.find_or_initialize_by(handle: "tuna")
tuna.assign_attributes(name: "マグロ", units: "kg", liquid: false, active: true)
tuna.save!

scallop = Oroshi::SupplyType.find_or_initialize_by(handle: "scallop")
scallop.assign_attributes(name: "ホタテ", units: "kg", liquid: false, active: true)
scallop.save!

puts "→ Supply type variations..."
salmon_fillet = Oroshi::SupplyTypeVariation.find_or_initialize_by(name: "フィレカット", supply_type: salmon)
salmon_fillet.assign_attributes(default_container_count: 10, active: true)
salmon_fillet.save!

salmon_whole = Oroshi::SupplyTypeVariation.find_or_initialize_by(name: "丸ごと", supply_type: salmon)
salmon_whole.assign_attributes(default_container_count: 5, active: true)
salmon_whole.save!

tuna_saku = Oroshi::SupplyTypeVariation.find_or_initialize_by(name: "サク", supply_type: tuna)
tuna_saku.assign_attributes(default_container_count: 20, active: true)
tuna_saku.save!

scallop_live = Oroshi::SupplyTypeVariation.find_or_initialize_by(name: "活", supply_type: scallop)
scallop_live.assign_attributes(default_container_count: 15, active: true)
scallop_live.save!

# Link suppliers to supply type variations
sapporo_salmon.supply_type_variation_ids = [ salmon_fillet.id, salmon_whole.id ]
sapporo_salmon.save!
hakodate_fish.supply_type_variation_ids = [ salmon_fillet.id, tuna_saku.id ]
hakodate_fish.save!
aomori_seafood.supply_type_variation_ids = [ scallop_live.id, tuna_saku.id ]
aomori_seafood.save!

# ============================================================================
# BUYERS
# ============================================================================

puts "→ Buyers..."
tsukiji = Oroshi::Buyer.find_or_initialize_by(handle: "tsukiji-market")
tsukiji.assign_attributes(
  name: "築地市場",
  entity_type: :wholesale_market,
  handling_cost: 1500,
  daily_cost: 800,
  optional_cost: 0,
  commission_percentage: 5.0,
  color: "#4ecdc4",
  active: true
)
tsukiji.save!

toyosu = Oroshi::Buyer.find_or_initialize_by(handle: "toyosu-market")
toyosu.assign_attributes(
  name: "豊洲市場",
  entity_type: :wholesale_market,
  handling_cost: 2000,
  daily_cost: 1000,
  optional_cost: 0,
  commission_percentage: 6.0,
  color: "#ff6b6b",
  active: true
)
toyosu.save!

sapporo_central = Oroshi::Buyer.find_or_initialize_by(handle: "sapporo-central")
sapporo_central.assign_attributes(
  name: "札幌中央卸売市場",
  entity_type: :wholesale_market,
  handling_cost: 1200,
  daily_cost: 600,
  optional_cost: 0,
  commission_percentage: 4.5,
  color: "#95e1d3",
  active: true
)
sapporo_central.save!

direct_restaurant = Oroshi::Buyer.find_or_initialize_by(handle: "direct-restaurant")
direct_restaurant.assign_attributes(
  name: "レストラン直送",
  entity_type: :retailer,
  handling_cost: 500,
  daily_cost: 200,
  optional_cost: 0,
  commission_percentage: 0.0,
  color: "#f38181",
  active: true
)
direct_restaurant.save!

# ============================================================================
# PRODUCTS & VARIATIONS
# ============================================================================

puts "→ Products..."
salmon_pack = Oroshi::Product.find_or_initialize_by(name: "鮭パック")
salmon_pack.assign_attributes(
  units: "kg",
  supply_type: salmon,
  exterior_height: 5,
  exterior_width: 25,
  exterior_depth: 15,
  active: true
)
salmon_pack.save!

tuna_pack = Oroshi::Product.find_or_initialize_by(name: "マグロパック")
tuna_pack.assign_attributes(
  units: "kg",
  supply_type: tuna,
  exterior_height: 6,
  exterior_width: 30,
  exterior_depth: 20,
  active: true
)
tuna_pack.save!

scallop_pack = Oroshi::Product.find_or_initialize_by(name: "ホタテパック")
scallop_pack.assign_attributes(
  units: "kg",
  supply_type: scallop,
  exterior_height: 8,
  exterior_width: 25,
  exterior_depth: 25,
  active: true
)
scallop_pack.save!

# ============================================================================
# SHIPPING: Receptacles, Organizations, Methods
# ============================================================================

puts "→ Shipping receptacles..."
cold_box_s = Oroshi::ShippingReceptacle.find_or_initialize_by(handle: "cold-box-s")
cold_box_s.assign_attributes(
  name: "保冷箱S",
  cost: 800,
  default_freight_bundle_quantity: 10,
  interior_height: 20, interior_width: 30, interior_depth: 20,
  exterior_height: 25, exterior_width: 35, exterior_depth: 25,
  active: true
)
cold_box_s.save!

cold_box_m = Oroshi::ShippingReceptacle.find_or_initialize_by(handle: "cold-box-m")
cold_box_m.assign_attributes(
  name: "保冷箱M",
  cost: 1200,
  default_freight_bundle_quantity: 20,
  interior_height: 30, interior_width: 40, interior_depth: 30,
  exterior_height: 35, exterior_width: 45, exterior_depth: 35,
  active: true
)
cold_box_m.save!

cold_box_l = Oroshi::ShippingReceptacle.find_or_initialize_by(handle: "cold-box-l")
cold_box_l.assign_attributes(
  name: "保冷箱L",
  cost: 1800,
  default_freight_bundle_quantity: 30,
  interior_height: 40, interior_width: 50, interior_depth: 40,
  exterior_height: 45, exterior_width: 55, exterior_depth: 45,
  active: true
)
cold_box_l.save!

puts "→ Production zones..."
hokkaido_zone_a = Oroshi::ProductionZone.find_or_initialize_by(name: "北海道ゾーンA")
hokkaido_zone_a.active = true
hokkaido_zone_a.save!

hokkaido_zone_b = Oroshi::ProductionZone.find_or_initialize_by(name: "北海道ゾーンB")
hokkaido_zone_b.active = true
hokkaido_zone_b.save!

tohoku_zone = Oroshi::ProductionZone.find_or_initialize_by(name: "東北ゾーン")
tohoku_zone.active = true
tohoku_zone.save!

puts "→ Product variations..."
salmon_1kg = Oroshi::ProductVariation.find_or_initialize_by(handle: "salmon-fillet-1kg", product: salmon_pack)
salmon_1kg.assign_attributes(
  name: "鮭フィレ 1kg",
  primary_content_volume: 1.0,
  default_shipping_receptacle: cold_box_m,
  primary_content_country_id: 392,
  primary_content_subregion_id: 1,
  shelf_life: 7,
  active: true
)
salmon_1kg.production_zone_ids = [ hokkaido_zone_a.id ]
salmon_1kg.supply_type_variation_ids = [ salmon_fillet.id ]
salmon_1kg.save!

salmon_500g = Oroshi::ProductVariation.find_or_initialize_by(handle: "salmon-fillet-500g", product: salmon_pack)
salmon_500g.assign_attributes(
  name: "鮭フィレ 500g",
  primary_content_volume: 0.5,
  default_shipping_receptacle: cold_box_s,
  primary_content_country_id: 392,
  primary_content_subregion_id: 1,
  shelf_life: 5,
  active: true
)
salmon_500g.production_zone_ids = [ hokkaido_zone_a.id ]
salmon_500g.supply_type_variation_ids = [ salmon_fillet.id ]
salmon_500g.save!

tuna_saku_200g = Oroshi::ProductVariation.find_or_initialize_by(handle: "tuna-saku-200g", product: tuna_pack)
tuna_saku_200g.assign_attributes(
  name: "マグロサク 200g",
  primary_content_volume: 0.2,
  default_shipping_receptacle: cold_box_s,
  primary_content_country_id: 392,
  primary_content_subregion_id: 1,
  shelf_life: 3,
  active: true
)
tuna_saku_200g.production_zone_ids = [ hokkaido_zone_b.id ]
tuna_saku_200g.supply_type_variation_ids = [ tuna_saku.id ]
tuna_saku_200g.save!

scallop_1kg = Oroshi::ProductVariation.find_or_initialize_by(handle: "scallop-live-1kg", product: scallop_pack)
scallop_1kg.assign_attributes(
  name: "活ホタテ 1kg",
  primary_content_volume: 1.0,
  default_shipping_receptacle: cold_box_m,
  primary_content_country_id: 392,
  primary_content_subregion_id: 2,
  shelf_life: 5,
  active: true
)
scallop_1kg.production_zone_ids = [ tohoku_zone.id ]
scallop_1kg.supply_type_variation_ids = [ scallop_live.id ]
scallop_1kg.save!

puts "→ Shipping organizations & methods..."
oroshi_express = Oroshi::ShippingOrganization.find_or_initialize_by(handle: "oroshi-express")
oroshi_express.assign_attributes(name: "オロシエクスプレス", active: true)
oroshi_express.save!

yamato_cold = Oroshi::ShippingOrganization.find_or_initialize_by(handle: "yamato-cold")
yamato_cold.assign_attributes(name: "ヤマト運輸 クール便", active: true)
yamato_cold.save!

cold_cargo = Oroshi::ShippingMethod.find_or_initialize_by(handle: "cold-cargo", shipping_organization: oroshi_express)
cold_cargo.assign_attributes(
  name: "冷蔵便",
  daily_cost: 2000,
  per_shipping_receptacle_cost: 400,
  per_freight_unit_cost: 1000,
  active: true
)
cold_cargo.buyer_ids = [ tsukiji.id, toyosu.id, sapporo_central.id ]
cold_cargo.save!

frozen_cargo = Oroshi::ShippingMethod.find_or_initialize_by(handle: "frozen-cargo", shipping_organization: oroshi_express)
frozen_cargo.assign_attributes(
  name: "冷凍便",
  daily_cost: 2500,
  per_shipping_receptacle_cost: 500,
  per_freight_unit_cost: 1200,
  active: true
)
frozen_cargo.buyer_ids = [ tsukiji.id, toyosu.id ]
frozen_cargo.save!

direct_delivery = Oroshi::ShippingMethod.find_or_initialize_by(handle: "direct-delivery", shipping_organization: yamato_cold)
direct_delivery.assign_attributes(
  name: "直送便",
  daily_cost: 1500,
  per_shipping_receptacle_cost: 300,
  per_freight_unit_cost: 800,
  active: true
)
direct_delivery.buyer_ids = [ direct_restaurant.id ]
direct_delivery.save!

# ============================================================================
# ORDER CATEGORIES
# ============================================================================

puts "→ Order categories..."
regular_order = Oroshi::OrderCategory.find_or_initialize_by(name: "通常注文")
regular_order.color = "#1e90ff"
regular_order.save!

urgent_order = Oroshi::OrderCategory.find_or_initialize_by(name: "緊急注文")
urgent_order.color = "#ff4444"
urgent_order.save!

sample_order = Oroshi::OrderCategory.find_or_initialize_by(name: "サンプル注文")
sample_order.color = "#ffa500"
sample_order.save!

test_order = Oroshi::OrderCategory.find_or_initialize_by(name: "試験注文")
test_order.color = "#9b59b6"
test_order.save!

# ============================================================================
# ORDERS & ORDER TEMPLATES
# ============================================================================

puts "→ Order templates..."
# OrderTemplate requires an associated Order with the template data
# Create template orders first
salmon_template_order = Oroshi::Order.find_or_create_by!(
  buyer: tsukiji,
  product_variation: salmon_1kg,
  shipping_receptacle: salmon_1kg.default_shipping_receptacle,
  shipping_method: cold_cargo,
  item_quantity: 50,
  receptacle_quantity: 5,
  freight_quantity: 2,
  shipping_date: Date.today + 1,
  arrival_date: Date.today + 2,
  manufacture_date: Date.today,
  expiration_date: Date.today + 7,
  is_order_template: true
)
salmon_template_order.order_category_ids = [ regular_order.id ] if salmon_template_order.order_category_ids.empty?

salmon_weekly = Oroshi::OrderTemplate.find_or_initialize_by(order: salmon_template_order)
salmon_weekly.assign_attributes(
  template_name: "週次サーモン配送",
  shipping_date_offset_days: 1,
  arrival_date_offset_days: 2,
  manufacture_date_offset_days: 0,
  expiration_date_offset_days: 7,
  active: true
)
salmon_weekly.save!

tuna_template_order = Oroshi::Order.find_or_create_by!(
  buyer: toyosu,
  product_variation: tuna_saku_200g,
  shipping_receptacle: tuna_saku_200g.default_shipping_receptacle,
  shipping_method: cold_cargo,
  item_quantity: 100,
  receptacle_quantity: 10,
  freight_quantity: 3,
  shipping_date: Date.today + 2,
  arrival_date: Date.today + 3,
  manufacture_date: Date.today,
  expiration_date: Date.today + 3,
  is_order_template: true
)
tuna_template_order.order_category_ids = [ regular_order.id ] if tuna_template_order.order_category_ids.empty?

tuna_biweekly = Oroshi::OrderTemplate.find_or_initialize_by(order: tuna_template_order)
tuna_biweekly.assign_attributes(
  template_name: "隔週マグロ配送",
  shipping_date_offset_days: 2,
  arrival_date_offset_days: 3,
  manufacture_date_offset_days: 0,
  expiration_date_offset_days: 3,
  active: true
)
tuna_biweekly.save!

puts "→ Sample orders..."
# Create orders for the past 2 weeks with various statuses
base_date = Date.today

# Recent orders (last week)
(-7..-1).each do |days_ago|
  order_date = base_date + days_ago

  # Morning salmon order to Tsukiji
  order = Oroshi::Order.find_or_create_by!(
    buyer: tsukiji,
    product_variation: salmon_1kg,
    shipping_receptacle: salmon_1kg.default_shipping_receptacle,
    shipping_method: cold_cargo,
    item_quantity: 30 + rand(20),
    receptacle_quantity: 3 + rand(2),
    freight_quantity: 1 + rand(1),
    shipping_date: order_date,
    arrival_date: order_date + 1,
    manufacture_date: order_date - 1,
    expiration_date: order_date + 7,
    is_order_template: false
  )
  order.order_category_ids = [ regular_order.id ] if order.order_category_ids.empty?

  # Afternoon tuna order to Toyosu (every other day)
  if days_ago.even?
    order = Oroshi::Order.find_or_create_by!(
      buyer: toyosu,
      product_variation: tuna_saku_200g,
      shipping_receptacle: tuna_saku_200g.default_shipping_receptacle,
      shipping_method: cold_cargo,
      item_quantity: 80 + rand(40),
      receptacle_quantity: 8 + rand(4),
      freight_quantity: 2 + rand(2),
      shipping_date: order_date,
      arrival_date: order_date + 1,
      manufacture_date: order_date,
      expiration_date: order_date + 3,
      is_order_template: false
    )
    order.order_category_ids = [ regular_order.id ] if order.order_category_ids.empty?
  end

  # Scallop order to Sapporo (twice a week)
  if [ -6, -3, -1 ].include?(days_ago)
    order = Oroshi::Order.find_or_create_by!(
      buyer: sapporo_central,
      product_variation: scallop_1kg,
      shipping_receptacle: scallop_1kg.default_shipping_receptacle,
      shipping_method: cold_cargo,
      item_quantity: 20 + rand(10),
      receptacle_quantity: 2 + rand(1),
      freight_quantity: 1,
      shipping_date: order_date,
      arrival_date: order_date + 1,
      manufacture_date: order_date,
      expiration_date: order_date + 5,
      is_order_template: false
    )
    order.order_category_ids = [ regular_order.id ] if order.order_category_ids.empty?
  end
end

# Upcoming orders (next 7 days)
(0..6).each do |days_ahead|
  order_date = base_date + days_ahead
  category = [ regular_order, urgent_order, sample_order ].sample
  product_var = [ salmon_1kg, salmon_500g, tuna_saku_200g, scallop_1kg ].sample

  order = Oroshi::Order.find_or_create_by!(
    buyer: [ tsukiji, toyosu, sapporo_central ].sample,
    product_variation: product_var,
    shipping_receptacle: product_var.default_shipping_receptacle,
    shipping_method: cold_cargo,
    item_quantity: 20 + rand(50),
    receptacle_quantity: 2 + rand(5),
    freight_quantity: 1 + rand(2),
    shipping_date: order_date,
    arrival_date: order_date + 1,
    manufacture_date: order_date - 1,
    expiration_date: order_date + (4..7).to_a.sample,
    is_order_template: false
  )
  order.order_category_ids = [ category.id ] if order.order_category_ids.empty?
end

# Special sample order for demonstration
order = Oroshi::Order.find_or_create_by!(
  buyer: direct_restaurant,
  product_variation: salmon_500g,
  shipping_receptacle: salmon_500g.default_shipping_receptacle,
  shipping_method: direct_delivery,
  item_quantity: 10,
  receptacle_quantity: 1,
  freight_quantity: 1,
  shipping_date: base_date,
  arrival_date: base_date + 1,
  manufacture_date: base_date,
  expiration_date: base_date + 5,
  is_order_template: false
)
order.order_category_ids = [ sample_order.id ] if order.order_category_ids.empty?

puts "✓ Created #{Oroshi::Order.count} orders"

# ============================================================================
# USER ONBOARDING PROGRESS
# ============================================================================

puts "→ User onboarding progress..."
User.find_each do |user|
  progress = user.onboarding_progress || user.create_onboarding_progress!

  # For admin users, mark onboarding as skipped (they have demo data)
  if user.admin?
    progress.update!(skipped_at: Time.current) unless progress.skipped?
  else
    # For non-admin users, don't auto-skip so they see the onboarding UI
    progress.update!(skipped_at: nil, checklist_dismissed_at: nil, completed_at: nil)
  end
end

puts "✓ Updated onboarding progress for #{User.count} users"

# ============================================================================
# SUMMARY
# ============================================================================

puts ""
puts "== Demo data seeding complete! =="
puts ""
puts "Summary:"
puts "  - Company settings: #{Setting.where(name: 'oroshi_company_settings').count}"
puts "  - Supply reception times: #{Oroshi::SupplyReceptionTime.count}"
puts "  - Supplier organizations: #{Oroshi::SupplierOrganization.count}"
puts "  - Suppliers: #{Oroshi::Supplier.count}"
puts "  - Supply types: #{Oroshi::SupplyType.count}"
puts "  - Supply type variations: #{Oroshi::SupplyTypeVariation.count}"
puts "  - Buyers: #{Oroshi::Buyer.count}"
puts "  - Products: #{Oroshi::Product.count}"
puts "  - Product variations: #{Oroshi::ProductVariation.count}"
puts "  - Shipping receptacles: #{Oroshi::ShippingReceptacle.count}"
puts "  - Shipping organizations: #{Oroshi::ShippingOrganization.count}"
puts "  - Shipping methods: #{Oroshi::ShippingMethod.count}"
puts "  - Production zones: #{Oroshi::ProductionZone.count}"
puts "  - Order categories: #{Oroshi::OrderCategory.count}"
puts "  - Order templates: #{Oroshi::OrderTemplate.count}"
puts "  - Orders: #{Oroshi::Order.count}"
puts "  - Users with onboarding: #{Oroshi::OnboardingProgress.count}"
puts ""
