# frozen_string_literal: true

module Oroshi::SupplyDateHelper
  def frame_id(*args)
    args.map { |arg| dom_id(arg) }.join("_")
  end

  def select_supplies(supplier, supply_type_variation)
    selected = @supplies.select do |supply|
      next unless supply

      supply.supplier == supplier &&
        supply.supply_type_variation == supply_type_variation &&
        supply.supply_date == @supply_date &&
        supply.supply_reception_time == @supply_reception_time
    end
    sort_into_entry_index(supply_type_variation, selected)
  end

  # SORT SUPPLIES START
  def sort_into_entry_index(supply_type_variation, selected)
    max_count = supply_type_variation.default_container_count
    unsortable = []
    sorted = Array.new(max_count)

    # First pass: place supplies with valid entry_indexes
    place_supplies_in_positions(selected, sorted, unsortable, max_count)

    # Second pass: fill remaining spots with unsortable supplies
    fill_empty_positions(sorted, unsortable)
  end

  def place_supplies_in_positions(supplies, sorted_array, unsortable_array, max_count)
    supplies.each do |supply|
      if is_unsortable?(supply, max_count)
        unsortable_array << supply
      elsif position_available?(sorted_array, supply.entry_index)
        sorted_array[supply.entry_index] = supply
      else
        handle_position_conflict(supply, sorted_array, unsortable_array, max_count)
      end
    end
  end

  def is_unsortable?(supply, max_count)
    supply.entry_index.nil? || supply.entry_index >= max_count
  end

  def position_available?(sorted_array, index)
    sorted_array[index].nil?
  end

  def handle_position_conflict(supply, sorted_array, unsortable_array, max_count)
    next_index = find_next_available_position(sorted_array, supply.entry_index, max_count)

    if next_index
      sorted_array[next_index] = supply
    else
      unsortable_array << supply
    end
  end

  def find_next_available_position(sorted_array, start_index, max_count)
    ((start_index + 1)...max_count).find { |i| sorted_array[i].nil? }
  end

  def fill_empty_positions(sorted_array, unsortable_array)
    sorted_array.map { |spot| spot || unsortable_array.pop }
  end
  # SORT SUPPLIES END

  def supply_type_variations_by_supply_type
    supply_type_variations = @supplier_organization.suppliers.map(&:supply_type_variations).flatten.uniq
    grouped_variations = supply_type_variations.group_by(&:supply_type).transform_values do |variations|
      variations.sort_by(&:position)
    end

    grouped_variations.sort_by do |supply_type, _variations|
      supply_type.position
    end.to_h
  end
end
