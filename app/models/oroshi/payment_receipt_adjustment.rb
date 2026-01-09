# frozen_string_literal: true

class Oroshi::PaymentReceiptAdjustment < ApplicationRecord
  # Associations
  belongs_to :payment_receipt, class_name: "Oroshi::PaymentReceipt"
  belongs_to :payment_receipt_adjustment_type, class_name: "Oroshi::PaymentReceiptAdjustmentType"

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }

  # Methods
  def type
    payment_receipt_adjustment_type
  end
end
