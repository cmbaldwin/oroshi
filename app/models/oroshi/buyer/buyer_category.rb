# frozen_string_literal: true

class Oroshi::Buyer::BuyerCategory < ApplicationRecord
  # Associations
  belongs_to :buyer, class_name: "Oroshi::Buyer"
  belongs_to :buyer_category, class_name: "Oroshi::BuyerCategory"

  # Validations
  validates :buyer_id, presence: true
  validates :buyer_category_id, presence: true
end
