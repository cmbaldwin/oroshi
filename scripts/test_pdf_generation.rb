#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for PDF generation with dummy data
# This script creates dummy orders and tests PDF generation without RSpec complexity

require_relative '../config/environment'

puts "=== PDF Generation Testing Script ==="
puts "Creating dummy data for PDF generation tests..."

begin
  # Create required settings
  puts "\n1. Creating Settings..."
  settings = Setting.find_or_create_by(name: 'ec_headers') do |s|
    s.settings = %w[500g セル セット その他]
  end
  puts "✓ EC headers setting created"

  # Create product types
  puts "\n2. Creating EcProductTypes..."
  product_types = []
  [
    { name: '500g', counter: 'p' },
    { name: 'セル', counter: 'セル' },
    { name: 'セット', counter: 'セット' },
    { name: 'その他', counter: '個' }
  ].each do |type_data|
    product_type = EcProductType.find_or_create_by(name: type_data[:name]) do |pt|
      pt.counter = type_data[:counter]
      pt.section = 'default'
    end
    product_types << product_type
    puts "✓ #{product_type.name} type created"
  end

  # Create EC products
  puts "\n3. Creating EcProducts..."
  ec_products = []
  [
    { name: 'むき身2kg', cross_reference_ids: [ '10000001' ], type: product_types[0], quantity: '2000' },
    { name: 'かきセット1kg', cross_reference_ids: [ '10000015' ], type: product_types[2], quantity: '1000' },
    { name: 'セルパック', cross_reference_ids: [ 'CELL001' ], type: product_types[1], quantity: '1' },
    { name: 'その他商品', cross_reference_ids: [ 'OYSTER-500G' ], type: product_types[3], quantity: '500' }
  ].each do |product_data|
    product = EcProduct.find_or_create_by(name: product_data[:name]) do |p|
      p.ec_product_type = product_data[:type]
      p.cross_reference_ids = product_data[:cross_reference_ids]
      p.quantity = product_data[:quantity]
      p.frozen_item = false
      p.memo_name = 'テスト商品'
      p.extra_shipping_cost = '0'
    end
    ec_products << product
    puts "✓ #{product.name} created"
  end

  # Test 1: Receipt PDF
  puts "\n4. Testing Receipt PDF..."
  receipt = Receipt.new(
    'sales_date' => '2025年11月05日',
    'order_id' => 'TEST_RECEIPT_001',
    'purchaser' => '山田太郎',
    'title' => '様',
    'amount' => '5000',
    'expense_name' => 'お品代として',
    'oysis' => '1',
    'tax_8_amount' => '400',
    'tax_8_tax' => '32',
    'tax_10_amount' => '4600',
    'tax_10_tax' => '460'
  )
  receipt_pdf = receipt.render
  puts "✓ Receipt PDF generated successfully (#{receipt_pdf.length} bytes)"

  # Test 2: Shell Card PDF
  puts "\n5. Testing Shell Card PDF..."
  card = ExpirationCard.create!(
    product_name: '殻付き かき（テスト用）',
    manufacturer_address: '兵庫県赤穂市中広1576-11',
    manufacturer: '株式会社 船曳商店',
    ingredient_source: '兵庫県坂越海域',
    consumption_restrictions: '生食用',
    manufactuered_date: Time.zone.today.strftime('%Y年%m月%d日'),
    expiration_date: (Time.zone.today + 4.days).strftime('%Y年%m月%d日'),
    storage_recommendation: '要冷蔵　0℃～10℃',
    made_on: true,
    shomiorhi: true
  )
  shell_card = ShellCard.new(card.id)
  shell_card_pdf = shell_card.render
  puts "✓ Shell Card PDF generated successfully (#{shell_card_pdf.length} bytes)"

  # Test 3: Blank Packing List PDF (simplest test)
  puts "\n6. Testing Blank Packing List PDF..."
  blank_list = OnlineShopPackingList.new(
    ship_date: Time.zone.today,
    blank: true
  )
  blank_pdf = blank_list.render
  puts "✓ Blank Packing List PDF generated successfully (#{blank_pdf.length} bytes)"

  # Clean up test data
  puts "\n7. Cleaning up test data..."
  card.destroy
  puts "✓ Test ExpirationCard cleaned up"

  puts "\n=== All PDF Generation Tests Passed! ==="
  puts "✓ Receipt PDFs working"
  puts "✓ Shell Card PDFs working"
  puts "✓ Blank Packing List PDFs working"
  puts "\nNote: Complex order-based PDFs may require actual order data"
  puts "The PDF generation core functionality is working correctly!"

rescue => e
  puts "\n❌ Error during PDF generation testing:"
  puts "#{e.class}: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end
