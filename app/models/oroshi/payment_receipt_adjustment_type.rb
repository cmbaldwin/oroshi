# frozen_string_literal: true

module Oroshi
  class PaymentReceiptAdjustmentType < ApplicationRecord
    include Oroshi::Activatable

    # Associations
    has_many :payment_receipt_adjustments, class_name: 'Oroshi::PaymentReceiptAdjustment'

    # Validations
    validates :name, presence: true
  end
end
