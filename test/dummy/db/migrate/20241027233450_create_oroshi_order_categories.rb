class CreateOroshiOrderCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_order_categories do |t|
      t.string :name

      t.timestamps
    end
  end
end
