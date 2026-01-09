# frozen_string_literal: true

FactoryBot.define do
  factory :oroshi_material, class: 'Oroshi::Material' do
    name { FFaker::LoremJA.words(2).join }
    cost { rand(1.0..100.0).round(2) }
    per { Oroshi::Material.pers.keys.sample }
    active { true }
    material_category do
      if Oroshi::MaterialCategory.count < 3
        create(:oroshi_material_category)
      else
        Oroshi::MaterialCategory.order('RANDOM()').first
      end
    end

    after(:create) do |material|
      # Attach a simple 1x1 pixel PNG image for testing
      png_data = "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\b\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\nIDATx\x9Cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xB4\x00\x00\x00\x00IEND\xAEB`\x82".dup.force_encoding('ASCII-8BIT')
      material.image.attach(
        io: StringIO.new(png_data),
        filename: 'placeholder.png',
        content_type: 'image/png'
      )
    end

    trait :with_products do
      after(:create) do |material|
        create_list(:oroshi_product, 3, materials: [material])
      end
    end
  end
end
