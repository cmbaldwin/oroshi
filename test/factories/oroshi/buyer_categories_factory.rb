# frozen_string_literal: true

FactoryBot.define do
  factory :oroshi_buyer_category, class: "Oroshi::BuyerCategory" do
    sequence(:name) { |n| "#{FFaker::LoremJA.words(2).join}#{n}" }
    sequence(:symbol) { |n| "BC#{n}" }
    color { "##{FFaker::Color.hex_code}" }
  end
end
