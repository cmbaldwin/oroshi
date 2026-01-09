# frozen_string_literal: true

module Oroshi::Positionable
  extend ActiveSupport::Concern

  # Where possible position is handled by js with muuri sorting and async posts
  # This is a backup for when js is disabled or fails

  included do
    # Validations
    validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    # Scopes
    default_scope { order(:position) }

    # Callbacks
    after_initialize :set_initial_position
    before_create :set_initial_position
    before_save :handle_inactive_position, if: :active_column_exists?
    before_save :handle_newly_active_position, if: :active_column_exists?
    after_save :reorder_positions

    private

    def set_initial_position
      return if position.present?

      self.position = max_position + 1
    end

    def max_position
      records_to_reorder.maximum(:position) || 1
    end

    def active_column_exists?
      self.class.column_names.include?("active")
    end

    def handle_inactive_position
      # return unless active is a column in the model
      return if active

      # Store old position for reordering
      old_position = position

      # Set position to 0 for inactive record
      self.position = 0

      # Reorder remaining active records
      transaction do
        records_to_reorder.where("position > ?", old_position)
                          .where(active: true)
                          .update_all("position = position - 1")
      end
    end

    def handle_newly_active_position
      return unless active && position.zero?

      self.position = max_position + 1
    end

    def reorder_positions
      # if the current record has a position equal to another record from records_to_reorder,
      # #add 1 to all records with a position greater than or equal to the current record
      other_records = records_to_reorder.where.not(id: id)
      if other_records.exists?(position: position)
        transaction do
          other_records.where("position >= ?", position).update_all("position = position + 1")
        end
      end

      resequence_positions
    end

    def resequence_positions
      records_to_reorder.order(:position).each_with_index do |record, index|
        record.update_column(:position, index + 1)
      end
    end

    def records_to_reorder
      base_scope = if belongs_to_parent?
                     parent_association.where(parent_foreign_key => send(parent_foreign_key))
      else
                     self.class
      end

      # Add active scope if model has active column
      base_scope = base_scope.where(active: true) if active_column_exists?

      base_scope.order(:position)
    end

    def belongs_to_parent?
      self.class.reflect_on_all_associations(:belongs_to).any?
    end

    def parent_association
      self.class
    end

    def parent_foreign_key
      # Should only be one parent association for positionable models, if any at all
      self.class.reflect_on_all_associations(:belongs_to).first.foreign_key
    end
  end
end
