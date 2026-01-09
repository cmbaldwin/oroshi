# frozen_string_literal: true

class Oroshi::Supply < ApplicationRecord
  include ActionView::RecordIdentifier # for broadcasts

  # Callbacks
  after_commit :update_join_records, if: -> { saved_change_to_quantity? }
  after_commit :ensure_unique_entry_index, on: %i[create update]

  # Associations
  belongs_to :supply_date, class_name: "Oroshi::SupplyDate", foreign_key: "supply_date_id", touch: true
  belongs_to :supplier, class_name: "Oroshi::Supplier"
  has_one :supplier_organization, through: :supplier, class_name: "Oroshi::SupplierOrganization"
  belongs_to :supply_type_variation, class_name: "Oroshi::SupplyTypeVariation"
  has_one :supply_type, through: :supply_type_variation, class_name: "Oroshi::SupplyType"
  belongs_to :supply_reception_time, class_name: "Oroshi::SupplyReceptionTime"

  # Validations
  validates :supply_date_id, presence: true
  validates :supplier_id, presence: true
  validates :supply_type_variation_id, presence: true
  validates :supply_reception_time_id, presence: true
  validates :quantity, :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Broadcasts
  after_create_commit lambda {
    broadcast_replace_to [ supply_date, supplier_organization, supply_reception_time, :supplies_list ],
                         target: "new_supply_#{supplier.id}_#{supply_type_variation.id}_#{entry_index}"
  }
  after_update_commit lambda {
    broadcast_replace_to [ supply_date, supplier_organization, supply_reception_time, :supplies_list ],
                         target: dom_id(self)
  }

  # Scopes
  scope :with_quantity, -> { where("quantity > 0") }
  scope :incomplete, -> { where("quantity > 0 AND price = 0") }
  scope :complete, -> { where("quantity > 0 AND price > 0") }

  def incomplete?
    quantity.positive? && price.zero?
  end

  private

  def update_join_records
    @sibling_supplies = supply_date.supplies.includes(supply_type_variation: :supply_type)
    supply_type_join
    supply_type_variation_join

    supply_date.suppliers << supplier unless supply_date.suppliers.exists?(supplier.id)
    return if supply_date.supplier_organizations.exists?(supplier.supplier_organization.id)

    supply_date.supplier_organizations << supplier.supplier_organization
  end

  def supply_type_join
    Oroshi::SupplyDate::SupplyType.find_or_create_by(
      supply_date: supply_date,
      supply_type: supply_type_variation.supply_type
    ).update(total: @sibling_supplies.select do |supply|
                      supply.supply_type_variation.supply_type == supply_type_variation.supply_type
                    end.sum(&:quantity))
  end

  def supply_type_variation_join
    Oroshi::SupplyDate::SupplyTypeVariation.find_or_create_by(
      supply_date: supply_date,
      supply_type_variation: supply_type_variation
    ).update(total: @sibling_supplies.select do |supply|
                      supply.supply_type_variation == supply_type_variation
                    end.sum(&:quantity))
  end

  def ensure_unique_entry_index
    return unless entry_index.present?

    duplicate_count = find_duplicate_count
    return unless duplicate_count.positive?

    next_index = find_next_available_index

    if next_index.nil?
      destroy_and_notify unless locked?
    else
      update_entry_index(next_index)
    end
  end

  def find_duplicate_count
    # Exclude self when checking for duplicates
    Oroshi::Supply.where(
      supply_date_id: supply_date_id,
      supplier_id: supplier_id,
      supply_type_variation_id: supply_type_variation_id,
      supply_reception_time_id: supply_reception_time_id,
      entry_index: entry_index
    ).where.not(id: id).count
  end

  def find_next_available_index
    # Get all used entry_indexes for this grouping
    used_indices = Oroshi::Supply.where(
      supply_date_id: supply_date_id,
      supplier_id: supplier_id,
      supply_type_variation_id: supply_type_variation_id,
      supply_reception_time_id: supply_reception_time_id
    ).pluck(:entry_index).compact

    # Find the first available index within container capacity
    max_container_count = supply_type_variation.default_container_count
    (0...max_container_count).find { |i| !used_indices.include?(i) }
  end

  def update_entry_index(new_index)
    # Use update_column to avoid triggering callbacks again
    update_column(:entry_index, new_index)

    # Re-broadcast the updated record to reflect the new position
    broadcast_updated_position
  end

  def broadcast_updated_position
    broadcast_replace_to [ supply_date, supplier_organization, supply_reception_time, :supplies_list ],
                         target: dom_id(self)
  end

  def destroy_and_notify
    # Destroy the record (unless locked)
    return unless destroy

    # Broadcast empty supply entry frame to reset the UI
    broadcast_replace_to [ supply_date, supplier_organization, supply_reception_time, :supplies_list ],
                         partial: "oroshi/supply_dates/show/empty_supply_entry_frame"
  end
end
