# frozen_string_literal: true

module Oroshi
  class SupplyDate < ApplicationRecord
    # Supplies
    has_many :supplies, class_name: 'Oroshi::Supply'
    # Suppliers
    has_and_belongs_to_many :suppliers,
                            class_name: 'Oroshi::Supplier',
                            join_table: 'oroshi_supply_date_suppliers'
    # Supplier Organizations
    has_and_belongs_to_many :supplier_organizations,
                            class_name: 'Oroshi::SupplierOrganization',
                            join_table: 'oroshi_supply_date_supplier_organizations'
    # Supply Types
    has_many :supply_date_supply_types, class_name: 'Oroshi::SupplyDate::SupplyType'
    has_many :supply_types, through: :supply_date_supply_types
    # Supply Type Variations
    has_many :supply_date_supply_type_variations, class_name: 'Oroshi::SupplyDate::SupplyTypeVariation'
    has_many :supply_type_variations, through: :supply_date_supply_type_variations
    # Invoices
    has_many :invoice_supply_dates, class_name: 'Oroshi::Invoice::SupplyDate'
    has_many :invoices, through: :invoice_supply_dates

    validates :date, presence: true, uniqueness: true

    scope :with_supplies, lambda {
                            joins(:supplies).where.not(oroshi_supplies: { quantity: 0 }).distinct
                          }

    def supply
      supplies.where('quantity > 0')
    end

    def incomplete_supply
      supplies.where('quantity > 0 AND price = 0')
    end

    def empty_supply
      supplies.where('quantity = 0 AND price = 0')
    end

    def clean_empty_supplies
      empty_supply.destroy_all
    end

    def reset_entry_indexes
      clean_empty_supplies
      grouped_supply.each_value do |supply_subset|
        supply_subset.sort_by(&:quantity).reverse.each_with_index do |supply, index|
          supply.update(entry_index: index)
        end
      end
      broadcast_refreshes
    end

    private

    def grouped_supply
      supply.group_by do |s|
        [s.supply_reception_time_id, s.supplier_id, s.supply_type_variation_id]
      end
    end

    def broadcast_refreshes
      supplier_organizations.each do |supplier_organization|
        supply_reception_times = supplier_organization.supply_reception_times
        supply_reception_times.each do |supply_reception_time|
          # Broadcast after indexes are updated
          Turbo::StreamsChannel.broadcast_refresh_to(
            [self, supplier_organization, supply_reception_time, :supplies_list]
          )
        end
      end
    end
  end
end
