# frozen_string_literal: true

class Credential < ApplicationRecord
  # Encrypt sensitive credential values using Active Record Encryption
  encrypts :value

  # Associations
  belongs_to :user, optional: true  # nil = system-wide credential

  # Enums
  enum :status, { active: 0, expired: 1, revoked: 2 }, prefix: true

  # Validations
  validates :service, :key_name, presence: true
  validates :key_name, uniqueness: { scope: [ :service, :user_id ] }
  validates :value, presence: true

  # Scopes
  scope :active, -> { where(status: :active).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :for_service, ->(service) { where(service: service) }
  scope :system_wide, -> { where(user_id: nil) }
  scope :expiring_soon, ->(days = 30) { where("expires_at IS NOT NULL AND expires_at BETWEEN ? AND ?", Time.current, days.days.from_now) }

  # Auto-expire credentials based on expires_at
  before_validation :check_expiration

  # Mask credentials for display (show first 8 and last 4 characters)
  def masked_value
    return nil if value.blank?
    return value if value.length < 12

    "#{value[0..7]}...#{value[-4..]}"
  end

  # Check if credential has expired
  def expired?
    expires_at&.< Time.current
  end

  # Revoke this credential
  def revoke!
    update(status: :revoked)
  end

  private

  def check_expiration
    self.status = :expired if expired? && status_active?
  end
end
