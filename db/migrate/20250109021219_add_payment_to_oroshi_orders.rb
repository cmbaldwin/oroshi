# frozen_string_literal: true

class AddPaymentToOroshiOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :oroshi_orders, :payment_receipt, foreign_key: { to_table: :oroshi_payment_receipts }
  end
end
