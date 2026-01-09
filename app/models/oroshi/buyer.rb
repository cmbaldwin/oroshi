# frozen_string_literal: true

class Oroshi::Buyer < ApplicationRecord
  # Callbacks
  include Oroshi::Activatable
  include Oroshi::Ransackable # required for Order Search form

  # Associations
  has_many :addresses, class_name: "Oroshi::Address", as: :addressable
  accepts_nested_attributes_for :addresses
  has_and_belongs_to_many :shipping_methods,
                          class_name: "Oroshi::ShippingMethod",
                          join_table: "oroshi_buyers_shipping_methods"
  has_many :shipping_organizations, through: :shipping_methods
  has_many :orders, class_name: "Oroshi::Order"
  has_many :buyer_buyer_categories, class_name: "Oroshi::Buyer::BuyerCategory", dependent: :destroy
  has_many :buyer_categories, through: :buyer_buyer_categories

  enum :entity_type, { wholesale_market: 0, retailer: 1, company: 2, individual: 3, other: 4 }

  # Validations
  validates :name, :handle, :handling_cost, :daily_cost, :entity_type,
            :optional_cost, :commission_percentage, presence: true
  validates :name, :handle, :representative_phone, :fax,
            :associated_system_id, uniqueness: true, allow_blank: true
  validates :color, format: { with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/, message: "\u6709\u52B9\u306A16\u9032\u6570\u30AB\u30E9\u30FC\u3067\u306A\u3051\u308C\u3070\u306A\u3089\u306A\u3044" }

  # Scopes
  scope :order_by_associated_system_id, -> { order(:associated_system_id) }

  def orders_with_date(date)
    orders.where(shipping_date: date)
  end

  def outstanding_payment_orders
    orders.where(payment_receipt_id: nil)
  end
end
