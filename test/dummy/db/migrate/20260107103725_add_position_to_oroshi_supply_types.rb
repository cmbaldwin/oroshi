class AddPositionToOroshiSupplyTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :oroshi_supply_types, :position, :integer
  end
end
