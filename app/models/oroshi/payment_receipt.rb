# frozen_string_literal: true

module Oroshi
  class PaymentReceipt < ApplicationRecord
    include Oroshi::Ransackable

    # Associations
    belongs_to :buyer, class_name: 'Oroshi::Buyer'
    has_many :orders, class_name: 'Oroshi::Order'
    has_many :payment_receipt_adjustments, class_name: 'Oroshi::PaymentReceiptAdjustment', dependent: :destroy
    accepts_nested_attributes_for :payment_receipt_adjustments, allow_destroy: true

    # Validations
    validates :total, :deposit_total, :deposit_date, :deadline_date, :issue_date, :buyer_id, presence: true
    validates :total, :deposit_total, numericality: { greater_than: 0 }

    # Callbacks
    before_destroy :remove_order_associations

    # Scopes
    # default sort by deposit_date desc
    default_scope { order(deposit_date: :desc) }

    # Methods
    def adjustments
      payment_receipt_adjustments
    end

    private

    def remove_order_associations
      orders.update_all(payment_receipt_id: nil)
    end
  end
end
