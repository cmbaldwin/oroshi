# frozen_string_literal: true

class CreateOroshiPaymentReceipts < ActiveRecord::Migration[8.0]
  def change
    create_table :oroshi_payment_receipts do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :oroshi_buyers }
      t.decimal :total, null: false, default: 0
      t.decimal :deposit_total, null: false, default: 0
      t.date :deposit_date, null: false
      t.date :deadline_date, null: false
      t.date :issue_date, null: false
      t.string :note

      t.timestamps
    end
  end
end
