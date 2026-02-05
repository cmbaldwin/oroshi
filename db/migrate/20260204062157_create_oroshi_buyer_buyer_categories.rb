class CreateOroshiBuyerBuyerCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :oroshi_buyer_buyer_categories do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :oroshi_buyers }
      t.references :buyer_category, null: false, foreign_key: { to_table: :oroshi_buyer_categories }
      t.timestamps
    end
  end
end
