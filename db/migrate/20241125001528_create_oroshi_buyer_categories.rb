# frozen_string_literal: true

class CreateOroshiBuyerCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :oroshi_buyer_categories do |t|
      t.string :name
      t.string :symbol
      t.string :color

      t.timestamps
    end
  end
end
