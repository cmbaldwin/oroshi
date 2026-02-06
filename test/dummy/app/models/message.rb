# frozen_string_literal: true

# Message model for tracking status of background job operations.
# Used by Oroshi jobs to communicate progress and results.
class Message < ApplicationRecord
  has_one_attached :stored_file

  after_initialize do
    self[:data] ||= {}
  end

  # Returns a mutable hash that automatically marks the attribute as changed
  def data
    @mutable_data ||= MutableJsonbHash.new(self, :data, read_attribute(:data) || {})
  end

  def data=(value)
    @mutable_data = nil
    write_attribute(:data, value || {})
  end

  # Simple wrapper that tracks mutations
  class MutableJsonbHash < HashWithIndifferentAccess
    def initialize(record, attribute, hash)
      @record = record
      @attribute = attribute
      super(hash)
    end

    def []=(key, value)
      super
      @record.send(:write_attribute, @attribute, to_h)
    end
  end
end
