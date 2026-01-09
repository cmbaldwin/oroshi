# frozen_string_literal: true

class Oroshi::ProductInventory < ApplicationRecord
  # Associations
  belongs_to :product_variation, class_name: "Oroshi::ProductVariation"
  has_many :orders, class_name: "Oroshi::Order"
  has_many :production_requests, class_name: "Oroshi::ProductionRequest"

  # Validations
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates_uniqueness_of :manufacture_date, scope: %i[product_variation_id expiration_date],
                                             message: "\u3053\u306E\u5728\u5EAB\u306F\u3082\u3046\u3059\u3067\u306B\u5B58\u5728\u3057\u3066\u307E\u3059"
  validates :manufacture_date, :expiration_date, presence: true
  validate :expiration_date_after_manufacture_date
  validate :immutable_fields, on: :update

  # Scopes
  scope :by_manufacture_date, ->(query_dates) { where(manufacture_date: query_dates) }

  def to_s
    "#{manufacture_date.strftime('%m月%d日')} +#{(expiration_date - manufacture_date).to_i}日"
  end

  def to_short_s
    "+#{(expiration_date - manufacture_date).to_i}日"
  end

  def freight_quantity
    # item quantity / items_per_box / freight_bundle_quantity
    quantity /
      product_variation.find_per_box_quantity /
      product_variation.default_shipping_receptacle.default_freight_bundle_quantity
  end

  def convert_outstanding_orders_to_requests
    order_item_sum = orders.map do |order|
      next if order.shipped?

      order.item_quantity
    end.sum

    request_item_sum = production_requests.map do |production_request|
      next if production_request.completed?

      [ production_request.request_quantity, production_request.fulfilled_quantity ].max
    end.sum

    request_amount = order_item_sum - request_item_sum
    return if request_amount.zero?

    production_requests.create!(product_inventory: self, request_quantity: request_amount)
  end

  private

  def expiration_date_after_manufacture_date
    return if manufacture_date.blank? || expiration_date.blank?

    return unless expiration_date <= manufacture_date

    errors.add(:expiration_date, "\u88FD\u9020\u65E5\u4EE5\u964D\u3067\u3042\u308B\u3053\u3068")
  end

  def immutable_fields
    return unless manufacture_date_changed? || expiration_date_changed? || product_variation_id_changed?

    errors.add(:base, "\u88FD\u9020\u65E5\u3001\u6D88\u8CBB\u671F\u9650\u3001\u88FD\u54C1\u30D0\u30EA\u30A8\u30FC\u30B7\u30E7\u30F3\u306F\u4F5C\u6210\u5F8C\u306B\u5909\u66F4\u3059\u308B\u3053\u3068\u306F\u3067\u304D\u307E\u305B\u3093\u3002")
  end
end
