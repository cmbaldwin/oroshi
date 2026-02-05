class AddPositionToOroshiSupplyTypeVariations < ActiveRecord::Migration[7.1]
  def change
    add_column :oroshi_supply_type_variations, :position, :integer, default: 1, null: false

    reversible do |dir|
      dir.up do
        Oroshi::SupplyTypeVariation.reset_column_information
        Oroshi::SupplyTypeVariation.find_each.with_index(1) do |variation, index|
          variation.update_columns(position: index)
        end
      end
    end
  end
end
