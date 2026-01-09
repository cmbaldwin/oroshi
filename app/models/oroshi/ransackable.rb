# frozen_string_literal: true

module Oroshi
  module Ransackable
    extend ActiveSupport::Concern

    included do
      # Ransack - because of the way the model is set up, we need to manually define these methods
      def self.ransackable_attributes(_auth_object = nil)
        column_names + _ransackers.keys
      end

      def self.ransackable_associations(_auth_object = nil)
        reflect_on_all_associations.map { |a| a.name.to_s }
      end

      def self.ransortable_attributes(auth_object = nil)
        ransackable_attributes(auth_object)
      end
    end
  end
end
