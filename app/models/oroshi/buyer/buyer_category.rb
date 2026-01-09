# frozen_string_literal: true

module Oroshi
  module Buyer
    class BuyerCategory < ApplicationRecord
      # Associations
      belongs_to :buyer, class_name: 'Oroshi::Order'
      belongs_to :buyer_category, class_name: 'Oroshi::OrderCategory'

      # Validations
      validates :buyer_id, presence: true
      validates :buyer_category_id, presence: true
    end
  end
end
