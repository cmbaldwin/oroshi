# frozen_string_literal: true

module Oroshi
  class OrderCategory < ApplicationRecord
    # Associations
    has_many :order_order_categories, class_name: 'Oroshi::Order::OrderCategory', dependent: :destroy
    has_many :orders, through: :order_order_categories

    # Validations
    validates :name, presence: true
    validates :color, presence: true

    # Scopes
    default_scope { order(:created_at) }
  end
end
