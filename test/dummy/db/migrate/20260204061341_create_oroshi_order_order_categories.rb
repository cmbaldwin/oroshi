class CreateOroshiOrderOrderCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :oroshi_order_order_categories do |t|
      t.references :order, null: false, foreign_key: { to_table: :oroshi_orders }
      t.references :order_category, null: false, foreign_key: { to_table: :oroshi_order_categories }
      t.timestamps
    end
  end
end
