# frozen_string_literal: true

module Oroshi
  module Order
    class OrderCategory < ApplicationRecord
      # Associations
      belongs_to :order, class_name: 'Oroshi::Order'
      belongs_to :order_category, class_name: 'Oroshi::OrderCategory'

      # Validations
      validates :order_id, presence: true
      validates :order_category_id, presence: true
    end
  end
end
