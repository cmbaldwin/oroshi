# frozen_string_literal: true

class AddColorToOroshiOrderCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :oroshi_order_categories, :color, :string
  end
end
