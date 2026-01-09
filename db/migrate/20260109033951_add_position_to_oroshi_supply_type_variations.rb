# frozen_string_literal: true

class AddPositionToOroshiSupplyTypeVariations < ActiveRecord::Migration[8.1]
  def change
    add_column :oroshi_supply_type_variations, :position, :integer, default: 1, null: false
  end
end
