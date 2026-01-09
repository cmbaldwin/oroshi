class CreateOroshiPaymentReceiptAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :oroshi_payment_receipt_adjustments do |t|
      t.references :payment_receipt, null: false, foreign_key: { to_table: :oroshi_payment_receipts }
      t.references :payment_receipt_adjustment_type, null: false,
                                                     foreign_key: { to_table: :oroshi_payment_receipt_adjustment_types }
      t.decimal :amount, null: false, default: 0

      t.timestamps
    end
  end
end
