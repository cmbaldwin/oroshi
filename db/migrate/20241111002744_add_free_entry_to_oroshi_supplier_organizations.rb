# frozen_string_literal: true

class AddFreeEntryToOroshiSupplierOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :oroshi_supplier_organizations, :free_entry, :boolean, default: false
  end
end
