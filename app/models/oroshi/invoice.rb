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
    errors.add(:supplier_organizations, "\u5C11\u306A\u304F\u3068\u30821\u3064\u5FC5\u8981\u3067\u3059") if supplier_organizations.empty?
  end

  def ensure_not_sent
    return unless sent_at.present?

    errors.add(:base, "\u9001\u4FE1\u6E08\u307F\u306E\u4ED5\u5207\u308A\u66F8\u3092\u524A\u9664\u3067\u304D\u307E\u305B\u3093\u3002")
    throw(:abort)
  end
end
