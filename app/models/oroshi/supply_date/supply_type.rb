# frozen_string_literal: true

module Oroshi
  module SupplyDate
    class SupplyType < ApplicationRecord
      belongs_to :supply_date, class_name: 'Oroshi::SupplyDate'
      belongs_to :supply_type, class_name: 'Oroshi::SupplyType'

      validates :total, numericality: { greater_than_or_equal_to: 0 }
    end
  end
end
