# frozen_string_literal: true

class Oroshi::OrderTemplate < ApplicationRecord
  # Associations
  belongs_to :order, class_name: "Oroshi::Order", inverse_of: :order_template, dependent: :destroy
  has_many :order_categories, through: :order
  has_one :buyer, through: :order
  has_many :buyer_categories, through: :buyer
  has_one :product_variation, through: :order
  has_one :product, through: :product_variation
  has_one :shipping_receptacle, through: :order
  has_one :shipping_method, through: :order
  has_one :shipping_organization, through: :shipping_method

  # Validations
  validates :order, presence: true

  # Scope
  default_scope do
    includes(:order, :buyer, :product_variation, :product,
             :shipping_receptacle, :shipping_method, :shipping_organization)
  end

  # Broadcasts
  after_update_commit lambda {
    broadcast_replace_to :oroshi_order_templates_list,
                         partial: "oroshi/orders/dashboard/orders/template",
                         locals: { template: self }
  }

  def item_quantity
    order.item_quantity
  end

  def receptacle_quantity
    order.receptacle_quantity
  end

  def freight_quantity
    order.freight_quantity
  end

  def shipping_arrival_difference
    order.arrival_date - order.shipping_date
  end
end
