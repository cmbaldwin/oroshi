# frozen_string_literal: true

module Oroshi
  class BuyerCategory < ApplicationRecord
    # Associations
    has_many :buyer_buyer_categories, class_name: 'Oroshi::Buyer::BuyerCategory', dependent: :destroy
    has_many :buyers, through: :buyer_buyer_categories

    # Validations
    validates :name, presence: true
    validates :symbol, presence: true
    validates :color, presence: true

    # Scopes
    default_scope { order(:created_at) }
  end
end
