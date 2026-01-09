# frozen_string_literal: true

FactoryBot.define do
  factory :oroshi_shipping_receptacle, class: 'Oroshi::ShippingReceptacle' do
    name { FFaker::LoremJA.word + %W[\u7BB1 \u6A3D].sample }
    sequence(:handle) { |n| "#{FFaker::Lorem.word}_#{n}" }
    cost { rand(1.0..100.0).round(2) }
    default_freight_bundle_quantity { rand(1..10) }
    interior_height { rand(1.0..100.0).round(2) }
    interior_width { rand(1.0..100.0).round(2) }
    interior_depth { rand(1.0..100.0).round(2) }
    exterior_height { rand(1.0..100.0).round(2) }
    exterior_width { rand(1.0..100.0).round(2) }
    exterior_depth { rand(1.0..100.0).round(2) }
    active { true }

    after(:create) do |shipping_receptacle|
      # Attach a simple 1x1 pixel PNG image for testing
      png_data = "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\b\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\nIDATx\x9Cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xB4\x00\x00\x00\x00IEND\xAEB`\x82".dup.force_encoding('ASCII-8BIT')
      shipping_receptacle.image.attach(
        io: StringIO.new(png_data),
        filename: 'placeholder.png',
        content_type: 'image/png'
      )
    end

    trait :with_production_requests do
      after(:create) do |shipping_receptacle|
        create_list(:oroshi_production_request, rand(1..3), shipping_receptacle: shipping_receptacle)
      end
    end

    trait :with_orders do
      after(:create) do |shipping_receptacle|
        create_list(:oroshi_order, rand(1..3), shipping_receptacle: shipping_receptacle)
      end
    end
  end
end
