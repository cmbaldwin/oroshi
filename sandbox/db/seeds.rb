# frozen_string_literal: true

puts "== Seeding Oroshi Sandbox Application =="
puts ""

# Create demo users
puts "Creating demo users..."

admin_user = User.find_or_initialize_by(email: "admin@oroshi.local")
admin_user.assign_attributes(
  username: "admin",
  password: "password123",
  password_confirmation: "password123",
  role: :admin,
  confirmed_at: Time.current
)
admin_user.skip_confirmation!
admin_user.save!
puts "✓ Admin user: admin@oroshi.local (password: password123)"

vip_user = User.find_or_initialize_by(email: "vip@oroshi.local")
vip_user.assign_attributes(
  username: "vip_user",
  password: "password123",
  password_confirmation: "password123",
  role: :vip,
  confirmed_at: Time.current
)
vip_user.skip_confirmation!
vip_user.save!
puts "✓ VIP user: vip@oroshi.local (password: password123)"

regular_user = User.find_or_initialize_by(email: "user@oroshi.local")
regular_user.assign_attributes(
  username: "regular_user",
  password: "password123",
  password_confirmation: "password123",
  role: :user,
  confirmed_at: Time.current
)
regular_user.skip_confirmation!
regular_user.save!
puts "✓ Regular user: user@oroshi.local (password: password123)"

puts ""
puts "== Seeding company information and master data =="

# Company info
Setting.find_or_initialize_by(name: "oroshi_company_settings")
       .update!(settings: {
         name: "株式会社オロシサーモン",
         postal_code: "060-0000",
         address: "北海道札幌市中央区1-1-1",
         phone: "011-000-0000",
         fax: "011-222-3333",
         mail: "info@oroshi.local",
         web: "https://example.oroshi.local",
         invoice_number: "T1234567890123"
       })
puts "✓ Company settings"

# Supply reception times
morning_reception = Oroshi::SupplyReceptionTime.find_or_create_by!(time_qualifier: "morning", hour: 9)
evening_reception = Oroshi::SupplyReceptionTime.find_or_create_by!(time_qualifier: "evening", hour: 17)
puts "✓ Supply reception times"

# Supplier organization
supplier_org = Oroshi::SupplierOrganization.find_or_initialize_by(entity_name: "北海水産協同組合")
supplier_org.assign_attributes(
  entity_type: :company,
  country_id: 392, # Japan
  subregion_id: 1, # Hokkaido
  micro_region: "札幌",
  invoice_number: "INV-100",
  fax: "011-222-3333",
  free_entry: false,
  active: true
)
supplier_org.supply_reception_times = [ morning_reception, evening_reception ]
supplier_org.save!
puts "✓ Supplier organization: #{supplier_org.entity_name}"

# Supplier
supplier = Oroshi::Supplier.find_or_initialize_by(company_name: "札幌サーモン株式会社")
supplier.assign_attributes(
  supplier_number: 1,
  representatives: [ "山田 太郎" ],
  invoice_number: "INV-100-1",
  supplier_organization: supplier_org,
  active: true
)
supplier.save!
puts "✓ Supplier: #{supplier.company_name}"

# Supply type and variation
supply_type = Oroshi::SupplyType.find_or_initialize_by(handle: "salmon")
supply_type.assign_attributes(name: "鮭", units: "kg", liquid: false, active: true)
supply_type.save!

supply_type_variation = Oroshi::SupplyTypeVariation.find_or_initialize_by(name: "フィレカット", supply_type: supply_type)
supply_type_variation.assign_attributes(default_container_count: 10, active: true)
supply_type_variation.save!

supplier.supply_type_variation_ids = [ supply_type_variation.id ]
puts "✓ Supply type: #{supply_type.name}"

# Buyer
buyer = Oroshi::Buyer.find_or_initialize_by(handle: "tsukiji-market")
buyer.assign_attributes(
  name: "築地市場",
  entity_type: :wholesale_market,
  handling_cost: 1500,
  daily_cost: 800,
  optional_cost: 0,
  commission_percentage: 5,
  color: "#4ecdc4",
  active: true
)
buyer.save!
puts "✓ Buyer: #{buyer.name}"

# Product
product = Oroshi::Product.find_or_initialize_by(name: "鮭パック")
product.assign_attributes(
  units: "kg",
  supply_type: supply_type,
  exterior_height: 5,
  exterior_width: 25,
  exterior_depth: 15,
  active: true
)
product.save!
puts "✓ Product: #{product.name}"

# Shipping receptacle
receptacle = Oroshi::ShippingReceptacle.find_or_initialize_by(handle: "cold-box-m")
receptacle.assign_attributes(
  name: "保冷箱M",
  cost: 1200,
  default_freight_bundle_quantity: 20,
  interior_height: 30,
  interior_width: 40,
  interior_depth: 30,
  exterior_height: 35,
  exterior_width: 45,
  exterior_depth: 35,
  active: true
)
receptacle.save!
puts "✓ Shipping receptacle: #{receptacle.name}"

# Production zone
production_zone = Oroshi::ProductionZone.find_or_initialize_by(name: "北海道ゾーンA")
production_zone.active = true
production_zone.save!
puts "✓ Production zone: #{production_zone.name}"

# Product variation
product_variation = Oroshi::ProductVariation.find_or_initialize_by(handle: "salmon-fillet-1kg", product: product)
product_variation.assign_attributes(
  name: "鮭フィレ 1kg",
  primary_content_volume: 1.0,
  default_shipping_receptacle: receptacle,
  primary_content_country_id: 392, # Japan numeric code
  primary_content_subregion_id: 1, # Hokkaido code
  shelf_life: 7,
  active: true
)
product_variation.production_zone_ids = [ production_zone.id ]
product_variation.supply_type_variation_ids = [ supply_type_variation.id ]
product_variation.save!
puts "✓ Product variation: #{product_variation.name}"

# Shipping organization & method
shipping_org = Oroshi::ShippingOrganization.find_or_initialize_by(handle: "oroshi-express")
shipping_org.assign_attributes(name: "オロシエクスプレス", active: true)
shipping_org.save!

shipping_method = Oroshi::ShippingMethod.find_or_initialize_by(handle: "cold-cargo", shipping_organization: shipping_org)
shipping_method.assign_attributes(
  name: "冷蔵便",
  daily_cost: 2000,
  per_shipping_receptacle_cost: 400,
  per_freight_unit_cost: 1000,
  active: true
)
shipping_method.buyer_ids = [ buyer.id ]
shipping_method.save!
puts "✓ Shipping method: #{shipping_method.name}"

# Order category
order_category = Oroshi::OrderCategory.find_or_initialize_by(name: "試験注文")
order_category.color = "#1e90ff"
order_category.save!
puts "✓ Order category: #{order_category.name}"

puts ""
puts "=="
puts "✓ Sandbox seeding complete!"
puts ""
puts "Demo users created:"
puts "  Admin:   admin@oroshi.local (password: password123)"
puts "  VIP:     vip@oroshi.local (password: password123)"
puts "  Regular: user@oroshi.local (password: password123)"
puts ""
puts "You can now start the server with: bin/rails server"
puts "Then visit: http://localhost:3000"
puts "=="
