# frozen_string_literal: true

FactoryBot.define do
  factory :oroshi_product_inventory, class: 'Oroshi::ProductInventory' do
    quantity { rand(1..100) }
    manufacture_date { Time.zone.today - rand(1..7).days }
    expiration_date { Time.zone.today + rand(14..60).days }

    association :product_variation, factory: :oroshi_product_variation
  end
end
