# frozen_string_literal: true

class Oroshi::Invoice < ApplicationRecord
  # Callbacks
  before_destroy :ensure_not_sent

  # Associations
  has_many :invoice_supply_dates, class_name: "Oroshi::Invoice::SupplyDate", dependent: :destroy
  has_many :supply_dates, through: :invoice_supply_dates
  has_many :supplies, through: :supply_dates
  has_many :invoice_supplier_organizations, class_name: "Oroshi::Invoice::SupplierOrganization", dependent: :destroy
  has_many :supplier_organizations, through: :invoice_supplier_organizations

  # Validations
  validates :start_date, :end_date, :invoice_layout, presence: true
  validates :send_email, inclusion: { in: [ true, false ] }
  validates :send_at, presence: true, if: :send_email?
  validate :at_least_one_supplier_organization

  # Enums
  enum :invoice_layout, { standard: 1, simple: 2 }

  # Broadcasts
  broadcasts :invoice, inserts_by: :replace

  # Scopes
  scope :unsent, -> { where(send_email: true, sent_at: nil).where("send_at <= ?", Time.zone.now) }

  def invoice_date
    send_at&.to_date
  end

  private

  def at_least_one_supplier_organization
    errors.add(:supplier_organizations, :at_least_one) if supplier_organizations.empty?
  end

  def ensure_not_sent
    return unless sent_at.present?

    errors.add(:base, :cannot_delete_sent)
    throw(:abort)
  end
end
