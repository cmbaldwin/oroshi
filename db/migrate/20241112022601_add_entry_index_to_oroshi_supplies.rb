class AddEntryIndexToOroshiSupplies < ActiveRecord::Migration[7.1]
  def change
    add_column :oroshi_supplies, :entry_index, :integer
  end
end
