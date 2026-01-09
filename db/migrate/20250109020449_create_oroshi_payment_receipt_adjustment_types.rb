# frozen_string_literal: true

class CreateOroshiPaymentReceiptAdjustmentTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :oroshi_payment_receipt_adjustment_types do |t|
      t.string :name, null: false
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
