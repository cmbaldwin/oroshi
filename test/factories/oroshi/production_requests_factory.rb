# frozen_string_literal: true

FactoryBot.define do
  factory :oroshi_production_request, class: 'Oroshi::ProductionRequest' do
    request_quantity { rand(1..100) }
    fulfilled_quantity { rand(1..100) }
    status { Oroshi::ProductionRequest.statuses.keys.sample }
    product_variation do
      if Oroshi::ProductVariation.none?
        create(:oroshi_product_variation)
      else
        Oroshi::ProductVariation.order('RANDOM()').first
      end
    end
    product_inventory do
      # Create product inventory for the associated product_variation
      if product_variation&.product_inventories&.any?
        product_variation.product_inventories.first
      else
        create(:oroshi_product_inventory, product_variation: product_variation)
      end
    end
    production_zone do
      if Oroshi::ProductionZone.none?
        create(:oroshi_production_zone)
      else
        Oroshi::ProductionZone.order('RANDOM()').first
      end
    end
    shipping_receptacle do
      if Oroshi::ShippingReceptacle.none?
        create(:oroshi_shipping_receptacle)
      else
        Oroshi::ShippingReceptacle.order('RANDOM()').first
      end
    end
  end
end
